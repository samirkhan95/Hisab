import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId; // The recipient
  final String title;
  final String body;
  final String type; // 'new_expense' | 'settled' | 'reminder'
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      isRead: data['is_read'] ?? false,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'created_at': Timestamp.fromDate(createdAt),
      'is_read': isRead,
    };
  }
}
