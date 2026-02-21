import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/category_service.dart';
import '../services/payment_method_service.dart';

class AIService {
  final CategoryService _categoryService;
  final PaymentMethodService _paymentMethodService;

  AIService(this._categoryService, this._paymentMethodService);

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
    int userId,
  ) async {
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

Respond ONLY with a valid JSON object:
{"amount": number, "category_id": number, "payment_method_id": number, "note": string, "date": string}
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;
      if (responseText != null) {
        final startIndex = responseText.indexOf('{');
        final endIndex = responseText.lastIndexOf('}') + 1;
        if (startIndex != -1 && endIndex != -1) {
          return jsonDecode(responseText.substring(startIndex, endIndex))
              as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to communicate with AI: $e');
    }
  }

  Future<Map<String, dynamic>?> parseImageToExpense(
    Uint8List imageBytes,
    int userId,
  ) async {
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

Respond ONLY with a valid JSON object:
{"amount": number, "category_id": number, "payment_method_id": number, "note": string, "date": string}
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
          return jsonDecode(responseText.substring(startIndex, endIndex))
              as Map<String, dynamic>;
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
      return response.text ??
          'I could not generate a response. Please try again.';
    } catch (e) {
      throw Exception('Chat failed: $e');
    }
  }
}
