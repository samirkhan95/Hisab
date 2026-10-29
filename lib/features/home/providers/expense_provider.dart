import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab/core/providers/firebase_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/expense_model.dart';

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userId = ref.watch(currentUserProvider)?.uid;

  if (userId == null) return Stream.value([]);

  // In Firebase, we fetch all expenses where current user is involved
  return firestore
      .collection('expenses')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
  });
});

final balanceProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final userId = ref.watch(currentUserProvider)?.uid;

  if (userId == null) return 0.0;

  double balance = 0.0;
  for (final expense in expenses) {
    if (expense.status == 'settled' || expense.isArchived) continue;

    if (expense.paidBy == userId) {
      // You paid
      if (expense.isSplit) {
        balance += expense.amount / 2;
      } else {
        balance += expense.amount;
      }
    } else {
      // They paid
      if (expense.isSplit) {
        balance -= expense.amount / 2;
      } else {
        balance -= expense.amount;
      }
    }
  }
  return balance;
});
