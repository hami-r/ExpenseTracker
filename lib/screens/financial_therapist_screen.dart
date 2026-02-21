import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/services/ai_service.dart';
import '../database/services/analytics_service.dart';
import '../database/services/transaction_service.dart';
import '../database/services/category_service.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/user_service.dart';
import '../database/database_helper.dart';
import '../providers/profile_provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────
class FinancialTherapistScreen extends StatefulWidget {
  const FinancialTherapistScreen({super.key});

  @override
  State<FinancialTherapistScreen> createState() =>
      _FinancialTherapistScreenState();
}

class _FinancialTherapistScreenState extends State<FinancialTherapistScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _userService = UserService();
  final _analyticsService = AnalyticsService();
  final _transactionService = TransactionService();
  final _categoryService = CategoryService();
  late final AIService _aiService;

  bool _isLoading = true;
  bool _isTyping = false;

  // Quick reply suggestions
  final List<String> _suggestions = [
    'Analyze my week',
    'Where am I overspending?',
    'What can I save?',
    'My subscription expenses',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _aiService = AIService(_categoryService, PaymentMethodService());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.isEmpty) {
        _loadContextAndGreet();
      } else {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContextAndGreet() async {
    // Capture context-dependent values before any async gap
    final profileId = context.read<ProfileProvider>().activeProfileId;
    final currencySymbol = context.read<ProfileProvider>().currencySymbol;

    final user = await _userService.getCurrentUser();
    if (user == null || user.userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    try {
      // Fetch all context in parallel
      final results = await Future.wait([
        _analyticsService.getTotalSpending(
          user.userId!,
          startOfMonth,
          endOfMonth,
          profileId: profileId,
        ),
        _analyticsService.getTotalSpending(
          user.userId!,
          sevenDaysAgo,
          now,
          profileId: profileId,
        ),
        _analyticsService.getTopCategories(
          user.userId!,
          startOfMonth,
          endOfMonth,
          5,
          profileId: profileId,
        ),
        _transactionService.getRecentTransactions(
          user.userId!,
          10,
          profileId: profileId,
        ),
        _analyticsService.getTotalBalance(user.userId!, profileId: profileId),
      ]);

      final monthSpend = results[0] as double;
      final weekSpend = results[1] as double;
      final topCategories = results[2] as List<CategorySpending>;
      final recentTx = results[3];
      final balance = results[4] as double;

      // Build the financial context string for Gemini
      final categoryLines = topCategories
          .map(
            (c) =>
                '  - ${c.category.name}: $currencySymbol${c.amount.toStringAsFixed(0)}',
          )
          .join('\n');

      // Get budgets from DB directly
      final db = await DatabaseHelper.instance.database;
      final budgetRows = await db.rawQuery(
        '''SELECT b.amount as budget_limit, c.name as cat_name,
           COALESCE(SUM(t.amount),0) as spent
           FROM budgets b
           LEFT JOIN categories c ON b.category_id = c.category_id
           LEFT JOIN transactions t ON t.category_id = b.category_id
             AND t.user_id = b.user_id
             AND strftime('%Y-%m', t.transaction_date) = ?
           WHERE b.user_id = ? AND b.month = ? AND b.year = ?
             AND b.profile_id = ?
           GROUP BY b.budget_id''',
        [
          '${now.year}-${now.month.toString().padLeft(2, '0')}',
          user.userId,
          now.month,
          now.year,
          profileId,
        ],
      );

      final budgetLines = budgetRows.isEmpty
          ? '  - No budgets set'
          : budgetRows
                .map((r) {
                  final limit = (r['budget_limit'] as num).toDouble();
                  final spent = (r['spent'] as num).toDouble();
                  final pct = limit > 0
                      ? (spent / limit * 100).toStringAsFixed(0)
                      : '?';
                  return '  - ${r['cat_name']}: $currencySymbol${spent.toStringAsFixed(0)} / $currencySymbol${limit.toStringAsFixed(0)} ($pct% used)';
                })
                .join('\n');

      final financialContext =
          '''
Net Balance: $currencySymbol${balance.toStringAsFixed(2)}
This Month's Total Spending: $currencySymbol${monthSpend.toStringAsFixed(2)}
Last 7 Days Spending: $currencySymbol${weekSpend.toStringAsFixed(2)}

Top Spending Categories This Month:
$categoryLines

Budget Status:
$budgetLines

Recent Transactions (last 10):
${(recentTx as dynamic).map((t) => '  - ${t.note ?? 'Expense'}: $currencySymbol${t.amount.toStringAsFixed(2)} on ${t.transactionDate}').join('\n')}
''';

      if (!mounted) return;
      final chatProvider = context.read<ChatProvider>();
      chatProvider.setContext(
        financialContext: financialContext,
        userId: user.userId!,
        profileId: profileId,
      );

      setState(() => _isLoading = false);

      // Proactive greeting — send an initial message from the AI
      await _sendInitialGreeting();
    } catch (e) {
      debugPrint('Error loading financial context: $e');
      setState(() => _isLoading = false);
      _addAIMessage(
        "Hey! I'm your Financial Therapist. I had trouble loading your data — please check your connection and try again 😊",
      );
    }
  }

  Future<void> _sendInitialGreeting() async {
    setState(() => _isTyping = true);
    final chatProvider = context.read<ChatProvider>();
    try {
      final reply = await _aiService.chatWithContext(
        history: [],
        userMessage:
            'Give me a short, friendly, proactive greeting based on my financial data. '
            'Mention one specific insight (like a category where I spent a lot or how my week looks). '
            'Keep it to 2-3 sentences.',
        financialContext: chatProvider.financialContext,
        userId: chatProvider.userId!,
        profileId: chatProvider.profileId!,
      );
      if (mounted) _addAIMessage(reply);
    } catch (_) {
      if (mounted) {
        _addAIMessage(
          "Hey! I'm your Financial Therapist 👋 Ask me anything about your spending, budgets, or savings — I have your data loaded and ready!",
        );
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _addAIMessage(String text) {
    if (mounted) {
      _addMessage(ChatMessage(role: MessageRole.model, text: text));
    }
  }

  void _addMessage(ChatMessage message) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.addMessage(message);
    chatProvider.addHistory({
      'role': message.role == MessageRole.user ? 'user' : 'model',
      'text': message.text,
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    final chatProvider = context.read<ChatProvider>();
    _inputController.clear();
    _addMessage(ChatMessage(role: MessageRole.user, text: trimmed));

    setState(() => _isTyping = true);

    try {
      final reply = await _aiService.chatWithContext(
        history: chatProvider.geminiHistory,
        userMessage: trimmed,
        financialContext: chatProvider.financialContext,
        userId: chatProvider.userId!,
        profileId: chatProvider.profileId!,
      );
      if (mounted) _addAIMessage(reply);
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        _addAIMessage(
          "I'm sorry, I'm having trouble thinking right now. Could you repeat that? 🧐",
        );
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _resetChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat?'),
        content: const Text(
          'This will clear the current conversation and start fresh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearChat();
              Navigator.pop(context);
              _loadContextAndGreet();
            },
            child: const Text(
              'New Chat',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, primaryColor),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(primaryColor)
                      : _buildMessageList(isDark, primaryColor),
                ),
                _buildInputBar(isDark, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              size: 28,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          // AI Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [primary, primary.withValues(alpha: 0.5)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF102217),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Therapist',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Always here for you',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
              size: 24,
            ),
            tooltip: 'New Chat',
            onPressed: _resetChat,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primary, strokeWidth: 2.5),
          const SizedBox(height: 20),
          Text(
            'Loading your financial data...',
            style: TextStyle(
              color: primary.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark, Color primary) {
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator bubble
        if (index == messages.length) {
          return _buildTypingIndicator(isDark, primary);
        }
        final msg = messages[index];
        final isUser = msg.role == MessageRole.user;

        // Date separator
        final showDate =
            index == 0 ||
            !_isSameDay(messages[index - 1].timestamp, msg.timestamp);

        return Column(
          children: [
            if (showDate) _buildDateSeparator(msg.timestamp, isDark),
            isUser
                ? _buildUserBubble(msg, isDark, primary)
                : _buildAIBubble(msg, isDark, primary, index),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateSeparator(DateTime date, bool isDark) {
    final label = DateFormat('EEEE, MMM d').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage msg, bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('h:mm a').format(msg.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.done_all_rounded,
                size: 14,
                color: primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'Read',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIBubble(
    ChatMessage msg,
    bool isDark,
    Color primary,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar dot
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [primary, primary.withValues(alpha: 0.4)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: Color(0xFF102217),
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mm a').format(msg.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1c3326) : Colors.white)
                            .withValues(alpha: 0.75),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                // Show suggestions after last AI message
                if (index == context.read<ChatProvider>().messages.length - 1 &&
                    !_isTyping)
                  _buildSuggestions(primary, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [primary, primary.withValues(alpha: 0.4)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: Color(0xFF102217),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1c3326) : Colors.white)
                      .withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(primary, 0),
                    const SizedBox(width: 4),
                    _buildDot(primary, 150),
                    const SizedBox(width: 4),
                    _buildDot(primary, 300),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Use the controller value to drive a sine wave for each dot with an offset
        final progress = (_animationController.value + (index * 0.2)) % 1.0;

        // Sine wave jump: smooth and cute
        final sinVal = math.sin(progress * 2 * math.pi);
        final yOffset = -6.0 * (sinVal > 0 ? sinVal : 0);

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Opacity(
            opacity: 0.4 + 0.6 * (sinVal > 0 ? sinVal : 0),
            child: child,
          ),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildSuggestions(Color primary, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _suggestions.map((s) {
            return GestureDetector(
              onTap: () => _sendMessage(s),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? primary : primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark, Color primary) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            10 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1c3326) : Colors.white).withValues(
              alpha: 0.8,
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TextField(
                    controller: _inputController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask your financial therapist...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.mic_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Send button
              GestureDetector(
                onTap: () => _sendMessage(_inputController.text),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF102217),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
