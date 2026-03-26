enum TherapistScopedDataKind {
  expenses,
  budget,
  loan,
  iou,
  receivable,
  reimbursement,
}

enum TherapistScopedIntent { share, askAi }

class TherapistScopedOption {
  final TherapistScopedDataKind kind;
  final TherapistScopedIntent intent;
  final int id;
  final String label;
  final String? subtitle;

  const TherapistScopedOption({
    required this.kind,
    required this.intent,
    required this.id,
    required this.label,
    this.subtitle,
  });
}

class TherapistScopedPreview {
  final TherapistScopedDataKind kind;
  final TherapistScopedIntent intent;
  final int? recordId;
  final String title;
  final String subtitle;
  final String body;
  final String shareText;
  final String aiContext;
  final String defaultQuestion;
  final bool actionsEnabled;

  const TherapistScopedPreview({
    required this.kind,
    required this.intent,
    this.recordId,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.shareText,
    required this.aiContext,
    required this.defaultQuestion,
    this.actionsEnabled = true,
  });
}

class TherapistScopedResolution {
  final TherapistScopedPreview? preview;
  final String? ambiguityMessage;
  final List<TherapistScopedOption> options;
  final bool shouldAutoAnalyze;
  final String? analysisPrompt;

  const TherapistScopedResolution({
    this.preview,
    this.ambiguityMessage,
    this.options = const [],
    this.shouldAutoAnalyze = false,
    this.analysisPrompt,
  });

  bool get hasPreview => preview != null;
  bool get isAmbiguous => ambiguityMessage != null && options.isNotEmpty;
}
