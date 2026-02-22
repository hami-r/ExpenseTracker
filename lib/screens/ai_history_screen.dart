import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/services/ai_history_service.dart';
import '../models/ai_history.dart';
import '../providers/profile_provider.dart';

class AIHistoryScreen extends StatefulWidget {
  const AIHistoryScreen({super.key});

  @override
  State<AIHistoryScreen> createState() => _AIHistoryScreenState();
}

class _AIHistoryScreenState extends State<AIHistoryScreen> {
  final _historyService = AIHistoryService();
  List<AIHistory> _history = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final profileId = context.read<ProfileProvider>().activeProfileId;
    final history = await _historyService.getHistory(profileId, limit: 100);
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  List<AIHistory> get _filteredHistory {
    if (_filter == 'all') return _history;
    return _history.where((h) => h.feature == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                _buildFilterChips(isDark, primaryColor),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredHistory.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildHistoryList(isDark, primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            'AI INTERACTION HISTORY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          IconButton(
            onPressed: _showClearDialog,
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, Color primary) {
    final chips = [
      {'label': 'All', 'id': 'all'},
      {'label': 'Chat', 'id': 'chat'},
      {'label': 'Voice', 'id': 'voice'},
      {'label': 'Receipts', 'id': 'receipt'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: chips.map((c) {
          final isSelected = _filter == c['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(c['label']!),
              onSelected: (val) => setState(() => _filter = c['id']!),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              selectedColor: primary.withValues(alpha: 0.2),
              checkmarkColor: primary,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? primary
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList(bool isDark, Color primary) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredHistory.length,
      itemBuilder: (context, index) {
        final entry = _filteredHistory[index];
        return _buildHistoryCard(entry, isDark, primary);
      },
    );
  }

  Widget _buildHistoryCard(AIHistory entry, bool isDark, Color primary) {
    IconData icon;
    Color iconColor;
    switch (entry.feature) {
      case 'chat':
        icon = Icons.chat_bubble_outline_rounded;
        iconColor = Colors.blueAccent;
        break;
      case 'voice':
        icon = Icons.mic_none_rounded;
        iconColor = Colors.orangeAccent;
        break;
      case 'receipt':
        icon = Icons.receipt_long_rounded;
        iconColor = Colors.greenAccent;
        break;
      default:
        icon = Icons.auto_awesome_rounded;
        iconColor = primary;
    }

    final dateStr = entry.timestamp != null
        ? DateFormat('MMM dd, hh:mm a').format(entry.timestamp!)
        : 'Unknown Time';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showDetails(entry),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No history found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(AIHistory entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailSheet(entry),
    );
  }

  Widget _buildDetailSheet(AIHistory entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final payload = entry.payload != null ? jsonDecode(entry.payload!) : {};

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              entry.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Feature: ${entry.feature.toUpperCase()}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Divider(height: 48),
            if (entry.feature == 'chat') ...[
              _buildDetailItem('Message', payload['question'] ?? ''),
              const SizedBox(height: 16),
              _buildDetailItem('AI Response', payload['answer'] ?? ''),
            ] else ...[
              for (var key in payload.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildDetailItem(key, payload[key].toString()),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white38 : Colors.black38,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, height: 1.5)),
      ],
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will delete all AI interaction records for this profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final profileId = context.read<ProfileProvider>().activeProfileId;
              await _historyService.clearHistory(profileId);
              Navigator.pop(context);
              _loadHistory();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
