import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/category_service.dart';
import '../services/payment_method_service.dart';
import '../services/ai_history_service.dart';
import '../../models/ai_history.dart';
import '../../models/category.dart';
import '../../models/payment_method.dart';

class AIService {
  final CategoryService _categoryService;
  final PaymentMethodService _paymentMethodService;
  final AIHistoryService _historyService = AIHistoryService();

  AIService(this._categoryService, this._paymentMethodService);

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final asString = value.toString().trim();
    if (asString.isEmpty) return null;
    return int.tryParse(asString) ?? double.tryParse(asString)?.toInt();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final asString = value.toString().trim().replaceAll(',', '');
    if (asString.isEmpty) return null;
    return double.tryParse(asString);
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value == null) return false;

    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  Category? _findCategoryById(List<Category> categories, int? categoryId) {
    if (categoryId == null) return null;
    for (final category in categories) {
      if (category.categoryId == categoryId) {
        return category;
      }
    }
    return null;
  }

  Category? _findCategoryByName(
    List<Category> categories,
    String? categoryName,
  ) {
    final name = categoryName?.trim().toLowerCase();
    if (name == null || name.isEmpty) return null;

    for (final category in categories) {
      if (category.name.toLowerCase() == name) {
        return category;
      }
    }
    return null;
  }

  PaymentMethod? _findPaymentMethodById(
    List<PaymentMethod> paymentMethods,
    int? paymentMethodId,
  ) {
    if (paymentMethodId == null) return null;
    for (final method in paymentMethods) {
      if (method.paymentMethodId == paymentMethodId) {
        return method;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _normalizeSplitItems(
    dynamic rawSplitItems,
    List<Category> categories,
  ) {
    if (rawSplitItems is! List) return [];

    final normalizedItems = <Map<String, dynamic>>[];

    for (final rawItem in rawSplitItems) {
      if (rawItem is! Map) continue;

      final item = Map<String, dynamic>.from(rawItem);
      final amount = _toDouble(item['amount']);
      if (amount == null || amount <= 0) continue;

      final categoryById = _findCategoryById(
        categories,
        _toInt(item['category_id']),
      );
      final categoryByName = _findCategoryByName(
        categories,
        item['category_name']?.toString() ?? item['category']?.toString(),
      );
      final category =
          categoryById ??
          categoryByName ??
          (categories.isNotEmpty ? categories.first : null);

      final rawName = item['name']?.toString().trim();
      final name = (rawName == null || rawName.isEmpty)
          ? (category?.name ?? 'Item')
          : rawName;

      normalizedItems.add({
        'name': name,
        'amount': amount,
        if (category?.categoryId != null) 'category_id': category!.categoryId,
        if (category != null) 'category_name': category.name,
      });
    }

    return normalizedItems;
  }

  Map<String, dynamic> _normalizeParsedExpense(
    Map<String, dynamic> parsedData,
    List<Category> categories,
    List<PaymentMethod> paymentMethods,
  ) {
    final splitItems = _normalizeSplitItems(
      parsedData['split_items'],
      categories,
    );
    final splitTotal = splitItems.fold<double>(
      0,
      (sum, item) => sum + ((_toDouble(item['amount']) ?? 0.0)),
    );

    final hasMultipleSplitItems = splitItems.length > 1;
    final isSplit = _toBool(parsedData['is_split']) || hasMultipleSplitItems;

    double amount = _toDouble(parsedData['amount']) ?? 0.0;
    if (isSplit && splitTotal > 0) {
      if (amount <= 0 || (amount - splitTotal).abs() > 0.01) {
        amount = splitTotal;
      }
    }

    final category =
        _findCategoryById(categories, _toInt(parsedData['category_id'])) ??
        _findCategoryByName(
          categories,
          parsedData['category_name']?.toString(),
        ) ??
        (splitItems.isNotEmpty
            ? _findCategoryById(
                categories,
                _toInt(splitItems.first['category_id']),
              )
            : null) ??
        (categories.isNotEmpty ? categories.first : null);

    final paymentMethod =
        _findPaymentMethodById(
          paymentMethods,
          _toInt(parsedData['payment_method_id']),
        ) ??
        (paymentMethods.isNotEmpty ? paymentMethods.first : null);

    final rawNote = parsedData['note']?.toString().trim();
    final note = (rawNote == null || rawNote.isEmpty)
        ? (isSplit ? 'Split expense' : 'Expense')
        : rawNote;

    final rawDate = parsedData['date']?.toString();
    final parsedDate = rawDate != null ? DateTime.tryParse(rawDate) : null;

    return {
      'amount': amount,
      'category_id': category?.categoryId,
      'payment_method_id': paymentMethod?.paymentMethodId,
      'note': note,
      'date': (parsedDate ?? DateTime.now()).toIso8601String(),
      'is_split': isSplit,
      'split_items': isSplit ? splitItems : <Map<String, dynamic>>[],
      if (category != null) 'category_name': category.name,
      if (paymentMethod != null) 'payment_method_name': paymentMethod.name,
    };
  }

  Future<String?> _getActiveApiKey() async {
    final prefs = await SharedPreferences.getInstance();

    final activeId = prefs.getString('active_ai_key_id');
    final keysJson = prefs.getString('ai_api_keys_list');

    if (activeId != null && keysJson != null) {
      try {
        final List<dynamic> mappedList = jsonDecode(keysJson);
        final activeKeyData = mappedList
            .cast<Map<String, dynamic>>()
            .firstWhere((k) => k['id'] == activeId, orElse: () => {});
        if (activeKeyData.containsKey('key') &&
            activeKeyData['key'].toString().isNotEmpty) {
          return activeKeyData['key'] as String?;
        }
      } catch (e) {
        // Fallthrough to legacy on JSON parse error
      }
    }

    final legacyKey = prefs.getString('gemini_api_key');
    if (legacyKey != null && legacyKey.isNotEmpty) {
      return legacyKey;
    }

    return null;
  }

  Future<Map<String, dynamic>?> parseNaturalLanguageExpense(
    String text,
    int userId, {
    required int profileId,
  }) async {
    final apiKey = await _getActiveApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key not configured. Please set it in AI Settings.');
    }

    final model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final categories = await _categoryService.getAllCategories(userId);
    final paymentMethods = await _paymentMethodService.getAllPaymentMethods(
      userId,
      profileId: profileId,
    );

    final categoriesStr = categories
        .map((c) => '{"id": ${c.categoryId}, "name": "${c.name}"}')
        .join(', ');
    final methodsStr = paymentMethods
        .map((m) => '{"id": ${m.paymentMethodId}, "name": "${m.name}"}')
        .join(', ');

    final prompt =
        '''
You are a highly intelligent financial assistant. Parse the natural language input and extract details into STRICT JSON.

User input: "$text"

Available Categories: [$categoriesStr]
Available Payment Methods: [$methodsStr]

Rules:
1. "amount": numerical amount (double).
2. "category_id": integer ID of the best matching category.
3. "payment_method_id": integer ID of the best matching payment method.
4. "note": concise title/note for the transaction.
5. "date": ISO 8601 date (YYYY-MM-DDTHH:mm:ss). Current date/time: ${DateTime.now().toIso8601String()}.
6. "is_split": boolean. Set true only when the input clearly includes multiple itemized sub-expenses.
7. "split_items": array of objects, each with "name", "amount", "category_id".
8. For non-split expenses, return "is_split": false and "split_items": [].
9. If "is_split" is true, make sure split item amounts add up to "amount".

Respond ONLY with a valid JSON object:
{"amount": number, "category_id": number, "payment_method_id": number, "note": string, "date": string, "is_split": boolean, "split_items": [{"name": string, "amount": number, "category_id": number}]}
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;
      if (responseText != null) {
        final startIndex = responseText.indexOf('{');
        final endIndex = responseText.lastIndexOf('}') + 1;
        if (startIndex != -1 && endIndex != -1) {
          final result =
              jsonDecode(responseText.substring(startIndex, endIndex))
                  as Map<String, dynamic>;
          final normalizedResult = _normalizeParsedExpense(
            result,
            categories,
            paymentMethods,
          );

          // Save to history
          await _historyService.saveEntry(
            AIHistory(
              userId: userId,
              profileId: profileId,
              feature: 'voice',
              title: text.length > 30 ? '${text.substring(0, 27)}...' : text,
              payload: jsonEncode(normalizedResult),
              timestamp: DateTime.now(),
            ),
          );

          return normalizedResult;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to communicate with AI: $e');
    }
  }

  Future<Map<String, dynamic>?> parseImageToExpense(
    Uint8List imageBytes,
    int userId, {
    required int profileId,
  }) async {
    final apiKey = await _getActiveApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key not configured. Please set it in AI Settings.');
    }

    final model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final categories = await _categoryService.getAllCategories(userId);
    final paymentMethods = await _paymentMethodService.getAllPaymentMethods(
      userId,
      profileId: profileId,
    );

    final categoriesStr = categories
        .map((c) => '{"id": ${c.categoryId}, "name": "${c.name}"}')
        .join(', ');
    final methodsStr = paymentMethods
        .map((m) => '{"id": ${m.paymentMethodId}, "name": "${m.name}"}')
        .join(', ');

    final prompt =
        '''
You are a financial assistant. Process the receipt image and extract transaction details into STRICT JSON.

Available Categories: [$categoriesStr]
Available Payment Methods: [$methodsStr]

Rules:
1. "amount": final total on the receipt (double).
2. "category_id": integer ID of the best matching category.
3. "payment_method_id": integer ID of the best matching payment method.
4. "note": concise vendor/purchase description.
5. "date": ISO 8601 date from the receipt. If not found, use ${DateTime.now().toIso8601String()}.
6. "is_split": boolean. Set true only if you can confidently extract multiple purchase items.
7. "split_items": array of objects with "name", "amount", and "category_id".
8. If you cannot confidently extract itemized splits, return "is_split": false and "split_items": [].

Respond ONLY with a valid JSON object:
{"amount": number, "category_id": number, "payment_method_id": number, "note": string, "date": string, "is_split": boolean, "split_items": [{"name": string, "amount": number, "category_id": number}]}
''';

    try {
      final imagePart = DataPart('image/jpeg', imageBytes);
      final response = await model.generateContent([
        Content.multi([TextPart(prompt), imagePart]),
      ]);
      final responseText = response.text;
      if (responseText != null) {
        final startIndex = responseText.indexOf('{');
        final endIndex = responseText.lastIndexOf('}') + 1;
        if (startIndex != -1 && endIndex != -1) {
          final result =
              jsonDecode(responseText.substring(startIndex, endIndex))
                  as Map<String, dynamic>;
          final normalizedResult = _normalizeParsedExpense(
            result,
            categories,
            paymentMethods,
          );

          // Save to history
          await _historyService.saveEntry(
            AIHistory(
              userId: userId,
              profileId: profileId,
              feature: 'receipt',
              title:
                  'Scanned Receipt: ${normalizedResult['note'] ?? 'Expense'}',
              payload: jsonEncode(normalizedResult),
              timestamp: DateTime.now(),
            ),
          );

          return normalizedResult;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to process image with AI: $e');
    }
  }

  /// Sends a message in the Financial Therapist chat with full financial context.
  ///
  /// [history] — conversation so far as [{role: 'user'|'model', text: '...'}]
  /// [userMessage] — the new user message to send
  /// [financialContext] — pre-built summary of the user's current finances
  Future<String> chatWithContext({
    required List<Map<String, String>> history,
    required String userMessage,
    required String financialContext,
    required int userId,
    required int profileId,
  }) async {
    final apiKey = await _getActiveApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key not configured. Please set it in AI Settings.');
    }

    final systemInstruction = Content.system('''
You are a warm, empathetic, and insightful Financial Therapist AI built into a personal finance app.
You have access to the user's real financial data shown below. Use it to give personalised, 
actionable, and specific advice. Be conversational, concise, and encouraging — not overly formal.

User's current financial snapshot:
$financialContext

Guidelines:
- Reference specific numbers from their data when relevant.
- Be proactive: if you notice something concerning or positive, mention it.
- Keep responses concise (2-4 sentences for simple questions).
- Use emoji sparingly to keep it friendly.
- Format amounts naturally (e.g. ₹5,000 not 5000.0).
- Today's date: ${DateTime.now().toString().split(' ')[0]}.
''');

    final model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      systemInstruction: systemInstruction,
    );

    final geminiHistory = history.map((msg) {
      final role = msg['role'] == 'user' ? 'user' : 'model';
      return Content(role, [TextPart(msg['text'] ?? '')]);
    }).toList();

    final chat = model.startChat(history: geminiHistory);

    try {
      final response = await chat.sendMessage(Content.text(userMessage));
      final reply =
          response.text ?? 'I could not generate a response. Please try again.';

      // Save to history
      await _historyService.saveEntry(
        AIHistory(
          userId: userId,
          profileId: profileId,
          feature: 'chat',
          title: userMessage.length > 40
              ? '${userMessage.substring(0, 37)}...'
              : userMessage,
          payload: jsonEncode({'question': userMessage, 'answer': reply}),
          timestamp: DateTime.now(),
        ),
      );

      return reply;
    } catch (e) {
      throw Exception('Chat failed: $e');
    }
  }
}
