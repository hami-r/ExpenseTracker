import 'therapist_scoped_preview.dart';

enum MessageRole { user, model }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final TherapistScopedPreview? scopedPreview;
  final List<TherapistScopedOption> scopedOptions;

  ChatMessage({
    required this.role,
    required this.text,
    this.scopedPreview,
    this.scopedOptions = const [],
  }) : timestamp = DateTime.now();
}
