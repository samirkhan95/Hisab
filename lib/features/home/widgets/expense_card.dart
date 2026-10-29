import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hisab/features/home/models/expense_model.dart';
import 'package:hisab/core/constants.dart';
import 'package:hisab/core/providers/firebase_provider.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';
import 'package:hisab/features/profile/providers/profile_provider.dart';
import 'package:hisab/core/widgets/avatar.dart';
import 'package:hisab/core/services/haptic_service.dart';
import 'package:hisab/core/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expense_sheet.dart';

class ExpenseCard extends ConsumerWidget {
  final Expense expense;
  final String currentUserId;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaidByMe = expense.paidBy == currentUserId;
    final dateStr = DateFormat('MMM dd, yyyy').format(expense.createdAt.toLocal());
    final isSettled = expense.status == 'settled';
    final profilesAsync = ref.watch(allProfilesProvider);

    Widget cardContent = Opacity(
      opacity: isSettled ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        elevation: isSettled ? 0 : 1,
        child: isPaidByMe
            ? ExpansionTile(
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                onExpansionChanged: (expanded) {
                  if (expanded) HapticService.light();
                },
                leading: profilesAsync.when(
                  data: (profiles) => Avatar(
                    imageUrl: profiles[expense.paidBy]?['avatar_url'],
                    radius: 20,
                  ),
                  loading: () => const CircleAvatar(radius: 20),
                  error: (_, __) => const Avatar(radius: 20),
                ),
                title: Text(
                  expense.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isSettled ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(dateStr),
                trailing: _buildTrailing(isPaidByMe),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('You paid'),
                            if (!isSettled)
                              ElevatedButton(
                                onPressed: () => _markAsDone(context, ref),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Mark as Done'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                HapticService.light();
                                _showEditSheet(context);
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: profilesAsync.when(
                  data: (profiles) => Avatar(
                    imageUrl: profiles[expense.paidBy]?['avatar_url'],
                    radius: 20,
                  ),
                  loading: () => const CircleAvatar(radius: 20),
                  error: (_, __) => const Avatar(radius: 20),
                ),
                title: Text(
                  expense.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isSettled ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(dateStr),
                trailing: _buildTrailing(isPaidByMe),
              ),
      ),
    );

    if (!isPaidByMe) return cardContent;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.horizontal,
      onUpdate: (details) {
        if (details.reached && !details.previousReached) {
          HapticService.light();
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Delete (Left to Right)
          HapticService.medium();
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Expense'),
              content:
                  Text('Are you sure you want to delete "${expense.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.alert),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        } else {
          // Archive (Right to Left)
          return true;
        }
      },
      onDismissed: (direction) async {
        final firestore = ref.read(firestoreProvider);

        if (direction == DismissDirection.startToEnd) {
          // Delete
          HapticService.heavy();
          await firestore.collection('expenses').doc(expense.id).delete();
        } else {
          // Archive / Unarchive
          HapticService.medium();
          await firestore
              .collection('expenses')
              .doc(expense.id)
              .update({'is_archived': !expense.isArchived});

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(expense.isArchived ? 'Unarchived' : 'Archived'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppColors.alert,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Icon(
          expense.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: cardContent,
    );
  }

  Widget _buildTrailing(bool isPaidByMe) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            '${AppConstants.currency}${expense.amount.toInt()}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: expense.status == 'settled'
                  ? AppColors.textSecondary
                  : (isPaidByMe ? AppColors.success : AppColors.alert),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: expense.status == 'settled'
                ? AppColors.success.withValues(alpha: 0.1)
                : Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Text(
            expense.status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: expense.status == 'settled' ? AppColors.success : Colors.amber[800],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _markAsDone(BuildContext context, WidgetRef ref) async {
    HapticService.medium();
    final firestore = ref.read(firestoreProvider);
    try {
      await firestore
          .collection('expenses')
          .doc(expense.id)
          .update({'status': 'settled', 'settled_at': FieldValue.serverTimestamp()});

      HapticService.success();

      // Add notification for the other person
      final user = ref.read(currentUserProvider);
      final userId = user?.uid;
      final otherId = expense.paidBy == userId ? expense.owedBy : expense.paidBy;
      final myName = user?.displayName ?? 'Your friend';

      await firestore.collection('notifications').add({
        'user_id': otherId,
        'title': 'Expense Settled',
        'body': '$myName marked "${expense.title}" as done',
        'type': 'settled',
        'created_at': FieldValue.serverTimestamp(),
        'is_read': false,
      });

      NotificationService.sendPushNotification(
        recipientUid: otherId,
        title: 'Expense Settled',
        body: '$myName marked "${expense.title}" as done',
        data: {'type': 'settled'},
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ExpenseSheet(expense: expense),
    );
  }
}
