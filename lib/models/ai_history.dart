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
    final map = <String, dynamic>{
      'history_id': historyId,
      'user_id': userId,
      'profile_id': profileId,
      'feature': feature,
      'title': title,
      'payload': payload,
    };

    // Let SQLite apply CURRENT_TIMESTAMP when timestamp is not provided.
    if (timestamp != null) {
      map['timestamp'] = timestamp!.toIso8601String();
    }

    return map;
  }

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTime) {
      return raw.toLocal();
    }

    if (raw is num) {
      final epoch = raw.toInt();
      final isMilliseconds = epoch > 100000000000;
      return DateTime.fromMillisecondsSinceEpoch(
        isMilliseconds ? epoch : epoch * 1000,
        isUtc: true,
      ).toLocal();
    }

    final value = raw.toString().trim();
    if (value.isEmpty) return null;

    final epoch = int.tryParse(value);
    if (epoch != null) {
      final isMilliseconds = epoch > 100000000000;
      return DateTime.fromMillisecondsSinceEpoch(
        isMilliseconds ? epoch : epoch * 1000,
        isUtc: true,
      ).toLocal();
    }

    // SQLite CURRENT_TIMESTAMP format: "yyyy-MM-dd HH:mm:ss[.SSS...]"
    final sqliteMatch = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?$',
    ).firstMatch(value);
    final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value);

    if (sqliteMatch != null && !hasTimezone) {
      final year = int.parse(sqliteMatch.group(1)!);
      final month = int.parse(sqliteMatch.group(2)!);
      final day = int.parse(sqliteMatch.group(3)!);
      final hour = int.parse(sqliteMatch.group(4)!);
      final minute = int.parse(sqliteMatch.group(5)!);
      final second = int.parse(sqliteMatch.group(6) ?? '0');

      final fractional = sqliteMatch.group(7) ?? '';
      final micros = fractional.isEmpty
          ? 0
          : int.parse('${fractional}000000'.substring(0, 6));

      final parsedUtc = DateTime.utc(
        year,
        month,
        day,
        hour,
        minute,
        second,
        micros ~/ 1000,
        micros % 1000,
      );
      return parsedUtc.toLocal();
    }

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return hasTimezone ? parsed.toLocal() : parsed;
    }

    final normalized = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    if (normalized != null) {
      return hasTimezone ? normalized.toLocal() : normalized;
    }

    return null;
  }

  factory AIHistory.fromMap(Map<String, dynamic> map) {
    return AIHistory(
      historyId: map['history_id'],
      userId: map['user_id'],
      profileId: map['profile_id'],
      feature: map['feature'],
      title: map['title'],
      payload: map['payload'],
      timestamp: _parseTimestamp(
        map['timestamp'] ?? map['created_at'] ?? map['date'],
      ),
    );
  }
}
