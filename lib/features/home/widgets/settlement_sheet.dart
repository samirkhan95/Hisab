import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hisab/core/providers/firebase_provider.dart';
import 'package:hisab/core/services/notification_service.dart';
import '../providers/expense_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants.dart';
import '../providers/friend_provider.dart';

class SettlementSheet extends ConsumerWidget {
  const SettlementSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);
    final expenses = ref.watch(expensesProvider).value ?? [];
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid;
    final myName = user?.displayName ?? 'You';
    final friendAsync = ref.watch(friendProvider);
    final friendName = friendAsync.value?['full_name'] ?? 'Friend';

    double totalPaidByMe = 0;
    double totalPaidByThem = 0;

    for (var e in expenses) {
      if (e.status == 'unsettled') {
        if (e.paidBy == userId) {
          totalPaidByMe += e.amount;
        } else {
          totalPaidByThem += e.amount;
        }
      }
    }

    String resultText;
    Color resultColor;
    if (balance > 0) {
      resultText = '$myName will get ${AppConstants.currency}${balance.toInt()}';
      resultColor = AppColors.success;
    } else if (balance < 0) {
      resultText = '$friendName will get ${AppConstants.currency}${balance.abs().toInt()}';
      resultColor = AppColors.alert;
    } else {
      resultText = 'All settled!';
      resultColor = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 200), // Increased bottom padding to 200 to fully clear the nav bar
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick Calculation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildRow('Total paid by you', totalPaidByMe),
          _buildRow('Total paid by $friendName', totalPaidByThem),
          const Divider(height: 32),
          Text(
            resultText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: resultColor,
            ),
          ),
          const SizedBox(height: 32),
          if (balance > 0)
            ElevatedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Settlement'),
                    content: const Text(
                        'Are you sure you want to mark all expenses as settled and reset the balance to zero?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Settle Up'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                final firestore = ref.read(firestoreProvider);
                
                // Mark all unsettled expenses as settled
                try {
                  // Firebase doesn't support multi-update easily without a transaction or batch
                  // Get all unsettled expenses first
                  final snapshot = await firestore
                      .collection('expenses')
                      .where('status', isEqualTo: 'unsettled')
                      .get();
                  
                  final batch = firestore.batch();
                  for (var doc in snapshot.docs) {
                    batch.update(doc.reference, {
                      'status': 'settled',
                      'settled_at': FieldValue.serverTimestamp()
                    });
                  }
                  await batch.commit();

                  // Add notification for the other person
                  final friend = ref.read(friendProvider).value;
                  if (friend != null) {
                    final myName = ref.read(currentUserProvider)?.displayName ?? 'Your friend';
                    await firestore.collection('notifications').add({
                      'user_id': friend['id'],
                      'title': 'All Settled Up',
                      'body': '$myName marked all expenses as settled',
                      'type': 'settled',
                      'created_at': FieldValue.serverTimestamp(),
                      'is_read': false,
                    });

                    NotificationService.sendPushNotification(
                      recipientUid: friend['id'],
                      title: 'All Settled Up',
                      body: '$myName marked all expenses as settled',
                      data: {'type': 'settled'},
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Settle Up'),
            )
          else if (balance < 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.alert.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Only the person receiving money can settle the account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.alert,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('${AppConstants.currency}${amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
