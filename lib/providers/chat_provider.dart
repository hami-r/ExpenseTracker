import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _geminiHistory = [];
  String _financialContext = '';
  int? _userId;
  int? _profileId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<Map<String, String>> get geminiHistory =>
      List.unmodifiable(_geminiHistory);
  String get financialContext => _financialContext;
  int? get userId => _userId;
  int? get profileId => _profileId;

  bool get isEmpty => _messages.isEmpty;

  void addMessage(ChatMessage message) {
    _messages.add(message);
    // Keep only last 50 messages for memory optimization
    if (_messages.length > 50) {
      _messages.removeAt(0);
    }
    notifyListeners();
  }

  void addHistory(Map<String, String> historyEntry) {
    _geminiHistory.add(historyEntry);
    // Keep history in sync with messages (sliding window)
    if (_geminiHistory.length > 50) {
      _geminiHistory.removeAt(0);
    }
    notifyListeners();
  }

  void setContext({
    required String financialContext,
    required int userId,
    required int profileId,
  }) {
    _financialContext = financialContext;
    _userId = userId;
    _profileId = profileId;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _geminiHistory.clear();
    _financialContext = '';
    _userId = null;
    _profileId = null;
    notifyListeners();
  }
}
