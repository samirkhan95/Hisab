import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String paidBy;
  final String owedBy;
  final String status; // 'unsettled' | 'settled'
  final bool isSplit;
  final bool isArchived;
  final String? note;
  final DateTime createdAt;
  final DateTime? settledAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.owedBy,
    required this.status,
    this.isSplit = true,
    this.isArchived = false,
    this.note,
    required this.createdAt,
    this.settledAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      paidBy: data['paid_by'] ?? '',
      owedBy: data['owed_by'] ?? '',
      status: data['status'] ?? 'unsettled',
      isSplit: data['is_split'] ?? true,
      isArchived: data['is_archived'] ?? false,
      note: data['note'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      settledAt: data['settled_at'] != null ? (data['settled_at'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'paid_by': paidBy,
      'owed_by': owedBy,
      'status': status,
      'is_split': isSplit,
      'is_archived': isArchived,
      'note': note,
      'created_at': Timestamp.fromDate(createdAt),
      'settled_at': settledAt != null ? Timestamp.fromDate(settledAt!) : null,
    };
  }
}
