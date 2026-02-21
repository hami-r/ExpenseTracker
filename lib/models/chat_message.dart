enum MessageRole { user, model }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.text})
    : timestamp = DateTime.now();
}
