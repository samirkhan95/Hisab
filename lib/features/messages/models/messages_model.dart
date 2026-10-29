import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String? expenseRef;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.expenseRef,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      expenseRef: data['expense_ref'],
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      expenseRef: json['expense_ref'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sender_id': senderId,
      'content': content,
      'created_at': Timestamp.fromDate(createdAt),
      'expense_ref': expenseRef,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'expense_ref': expenseRef,
    };
  }
}
