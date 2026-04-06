// lib/features/alerts/models/alert_model.dart
//
// Matches Django AppAlert model fields exactly:
//   AlertID, FarmerID (FK), Title, Message, alert_type,
//   IsRead, DateCreated, priority, district_target, expires_at

class AppAlert {
  final int alertId;
  final int? farmerId;
  final String title;
  final String message;
  final AlertType alertType;
  final bool isRead;
  final DateTime dateCreated;
  final AlertPriority priority;
  final String? districtTarget;
  final DateTime? expiresAt;
  final int? relatedCropId;

  const AppAlert({
    required this.alertId,
    this.farmerId,
    required this.title,
    required this.message,
    required this.alertType,
    required this.isRead,
    required this.dateCreated,
    required this.priority,
    this.districtTarget,
    this.expiresAt,
    this.relatedCropId,
  });

  // ── fromJson ─────────────────────────────────────────────────────────────
  // Handles both snake_case (API) and the Django PascalCase field names
  factory AppAlert.fromJson(Map<String, dynamic> json) {
    return AppAlert(
      alertId:       json['AlertID']        ?? json['alert_id']        ?? 0,
      farmerId:      json['FarmerID']       ?? json['farmer_id'],
      title:         json['Title']          ?? json['title']           ?? '',
      message:       json['Message']        ?? json['message']         ?? '',
      alertType:     AlertType.fromString(
                       json['alert_type']   ?? 'system'),
      isRead:        json['IsRead']         ?? json['is_read']         ?? false,
      dateCreated:   DateTime.parse(
                       json['DateCreated']  ?? json['date_created']
                       ?? DateTime.now().toIso8601String()),
      priority:      AlertPriority.fromString(
                       json['priority']     ?? 'medium'),
      districtTarget: json['district_target'],
      expiresAt:     json['expires_at'] != null
                       ? DateTime.tryParse(json['expires_at'])
                       : null,
      relatedCropId: json['RelatedCrop']    ?? json['related_crop'],
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'AlertID':         alertId,
    'FarmerID':        farmerId,
    'Title':           title,
    'Message':         message,
    'alert_type':      alertType.value,
    'IsRead':          isRead,
    'DateCreated':     dateCreated.toIso8601String(),
    'priority':        priority.value,
    'district_target': districtTarget,
    'expires_at':      expiresAt?.toIso8601String(),
    'RelatedCrop':     relatedCropId,
  };

  // ── copyWith ──────────────────────────────────────────────────────────────
  AppAlert copyWith({
    int? alertId,
    int? farmerId,
    String? title,
    String? message,
    AlertType? alertType,
    bool? isRead,
    DateTime? dateCreated,
    AlertPriority? priority,
    String? districtTarget,
    DateTime? expiresAt,
    int? relatedCropId,
  }) {
    return AppAlert(
      alertId:        alertId        ?? this.alertId,
      farmerId:       farmerId       ?? this.farmerId,
      title:          title          ?? this.title,
      message:        message        ?? this.message,
      alertType:      alertType      ?? this.alertType,
      isRead:         isRead         ?? this.isRead,
      dateCreated:    dateCreated    ?? this.dateCreated,
      priority:       priority       ?? this.priority,
      districtTarget: districtTarget ?? this.districtTarget,
      expiresAt:      expiresAt      ?? this.expiresAt,
      relatedCropId:  relatedCropId  ?? this.relatedCropId,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// True if expires_at is set and has passed
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Human-readable relative time e.g. "2 hours ago", "just now"
  String get timeAgo {
    final diff = DateTime.now().difference(dateCreated);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return '${dateCreated.day}/${dateCreated.month}/${dateCreated.year}';
  }

  @override
  String toString() =>
      'AppAlert(id: $alertId, type: ${alertType.value}, '
      'priority: ${priority.value}, read: $isRead)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppAlert && other.alertId == alertId;

  @override
  int get hashCode => alertId.hashCode;
}


// ════════════════════════════════════════════════════════════════════════════
// AlertType — matches Django ALERT_TYPE_CHOICES exactly
// ════════════════════════════════════════════════════════════════════════════

enum AlertType {
  weather  ('weather',  'Weather'),
  disease  ('disease',  'Disease Outbreak'),
  market   ('market',   'Market Price'),
  reminder ('reminder', 'Crop Reminder'),
  system   ('system',   'System');

  const AlertType(this.value, this.label);

  final String value;
  final String label;

  static AlertType fromString(String value) {
    return AlertType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AlertType.system,
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
// AlertPriority — matches Django PRIORITY_CHOICES exactly
// ════════════════════════════════════════════════════════════════════════════

enum AlertPriority {
  low    ('low',    'Low'),
  medium ('medium', 'Medium'),
  high   ('high',   'High — Urgent');

  const AlertPriority(this.value, this.label);

  final String value;
  final String label;

  static AlertPriority fromString(String value) {
    return AlertPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AlertPriority.medium,
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
// AlertsResponse — wraps the paginated API response from
//   GET /api/alerts/
//   { "count": 5, "unread_count": 2, "alerts": [...] }
// ════════════════════════════════════════════════════════════════════════════

class AlertsResponse {
  final int count;
  final int unreadCount;
  final List<AppAlert> alerts;

  const AlertsResponse({
    required this.count,
    required this.unreadCount,
    required this.alerts,
  });

  factory AlertsResponse.fromJson(Map<String, dynamic> json) {
    final rawAlerts = json['alerts'] as List<dynamic>? ?? [];
    return AlertsResponse(
      count:       json['count']        ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      alerts:      rawAlerts
                     .map((a) => AppAlert.fromJson(a as Map<String, dynamic>))
                     .toList(),
    );
  }

  factory AlertsResponse.empty() => const AlertsResponse(
    count: 0,
    unreadCount: 0,
    alerts: [],
  );
}