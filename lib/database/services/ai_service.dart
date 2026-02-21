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

    // 1. Try modern multi-key setup
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

    // 2. Fallback to legacy single key setup
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

    // Initialize the Gemini 3 Flash model
    final model = GenerativeModel(
      model: 'gemini-3-flash-preview', // Using the recommended Flash model
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    // Fetch context data
    final categories = await _categoryService.getAllCategories(userId);
    final paymentMethods = await _paymentMethodService.getAllPaymentMethods(
      userId,
    );

    // Build context strings
    final categoriesStr = categories
        .map((c) => '{"id": ${c.categoryId}, "name": "${c.name}"}')
        .join(', ');
    final methodsStr = paymentMethods
        .map((m) => '{"id": ${m.paymentMethodId}, "name": "${m.name}"}')
        .join(', ');

    final prompt =
        '''
You are a highly intelligent financial assistant. Your task is to parse a natural language input describing a financial transaction and extract the relevant details into a STRICT JSON format.

Here is the user's input:
"$text"

Context - Available Categories (You MUST choose the most appropriate category_id from this list. If it resembles income, pick an Income category, otherwise Expense):
[$categoriesStr]

Context - Available Payment Methods (You MUST choose the most appropriate payment_method_id from this list):
[$methodsStr]

Rules:
1. "amount": The parsed numerical amount (double).
2. "category_id": The integer ID of the best matching category from the context. If nothing fits exactly, pick the closest one (e.g., General or Miscellaneous).
3. "payment_method_id": The integer ID of the best matching payment method. (e.g., if they say "Cash", find the ID for Cash). Defaults to the first ID if unsure.
4. "note": A concise, useful title or note for the transaction.
5. "date": The date of the transaction in ISO 8601 format (YYYY-MM-DDTHH:mm:ss). If they say "yesterday", calculate yesterday's date relative to now. Assume today if not specified. Current date/time is ${DateTime.now().toIso8601String()}.

Respond ONLY with a valid JSON object matching this schema:
{
  "amount": number,
  "category_id": number,
  "payment_method_id": number,
  "note": string,
  "date": string
}
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText != null) {
        // Find JSON boundaries just in case markdown formatting creeps in
        final startIndex = responseText.indexOf('{');
        final endIndex = responseText.lastIndexOf('}') + 1;

        if (startIndex != -1 && endIndex != -1) {
          final jsonString = responseText.substring(startIndex, endIndex);
          return jsonDecode(jsonString) as Map<String, dynamic>;
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
You are a highly intelligent financial assistant. Your task is to process the provided receipt/bill image and extract the transaction details into a STRICT JSON format.

Context - Available Categories (You MUST choose the most appropriate category_id from this list):
[$categoriesStr]

Context - Available Payment Methods (You MUST choose the most appropriate payment_method_id from this list):
[$methodsStr]

Rules:
1. "amount": The final total amount on the receipt (double).
2. "category_id": The integer ID of the best matching category from the context based on the items purchased or the vendor.
3. "payment_method_id": The integer ID of the best matching payment method based on any card descriptors or payment types mentioned on the receipt (e.g., Visa, Cash).
4. "note": A concise, useful title or note describing the vendor or purchase.
5. "date": The date of the transaction found on the receipt in ISO 8601 format (YYYY-MM-DDTHH:mm:ss). If no date is found, use ${DateTime.now().toIso8601String()}.

Respond ONLY with a valid JSON object matching this schema:
{
  "amount": number,
  "category_id": number,
  "payment_method_id": number,
  "note": string,
  "date": string
}
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
          final jsonString = responseText.substring(startIndex, endIndex);
          return jsonDecode(jsonString) as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to process image with AI: $e');
    }
  }
}
