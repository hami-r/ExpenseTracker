class AIHistory {
  final int? historyId;
  final int userId;
  final int profileId;
  final String feature; // 'chat', 'voice', 'receipt'
  final String title;
  final String? payload; // JSON string
  final DateTime? timestamp;

  AIHistory({
    this.historyId,
    required this.userId,
    required this.profileId,
    required this.feature,
    required this.title,
    this.payload,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'history_id': historyId,
      'user_id': userId,
      'profile_id': profileId,
      'feature': feature,
      'title': title,
      'payload': payload,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  factory AIHistory.fromMap(Map<String, dynamic> map) {
    return AIHistory(
      historyId: map['history_id'],
      userId: map['user_id'],
      profileId: map['profile_id'],
      feature: map['feature'],
      title: map['title'],
      payload: map['payload'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : null,
    );
  }
}
