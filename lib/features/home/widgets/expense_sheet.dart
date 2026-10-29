import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab/core/providers/firebase_provider.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';
import 'package:hisab/features/home/providers/friend_provider.dart';
import 'package:hisab/features/home/widgets/hold_to_confirm_button.dart';
import 'package:hisab/core/constants.dart';
import 'package:hisab/core/services/haptic_service.dart';
import 'package:hisab/core/services/notification_service.dart';
import '../models/expense_model.dart';

class ExpenseSheet extends ConsumerStatefulWidget {
  final Expense? expense;

  const ExpenseSheet({super.key, this.expense});

  @override
  ConsumerState<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<ExpenseSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSplit = true;
  bool _isLoading = false;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toString();
      _isSplit = widget.expense!.isSplit;
      _totalAmount = widget.expense!.amount;
    }
    _amountController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateTotal);
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final text = _amountController.text;
    if (text.isEmpty) {
      setState(() => _totalAmount = 0.0);
      return;
    }

    // Split by comma and sum up
    final parts = text.split(',');
    double sum = 0.0;
    for (var part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) {
        sum += double.tryParse(trimmed) ?? 0.0;
      }
    }

    // Haptic feedback when a comma is added
    if (text.endsWith(',')) {
      HapticService.light();
    }

    setState(() => _totalAmount = sum);
  }

  void _saveExpense() async {
    final title = _titleController.text.trim();
    final user = ref.read(currentUserProvider);
    final userId = user?.uid;

    if (title.isNotEmpty && _totalAmount > 0 && userId != null) {
      setState(() => _isLoading = true);
      final firestore = ref.read(firestoreProvider);
      
      try {
        if (widget.expense == null) {
          final friend = ref.read(friendProvider).value;
          final friendId = friend?['id'] ?? userId;
          final myName = user?.displayName ?? 'Your friend';

          await Future.wait([
            firestore.collection('expenses').add({
              'title': title,
              'amount': _totalAmount,
              'paid_by': userId,
              'owed_by': friendId,
              'status': 'unsettled',
              'is_split': _isSplit,
              'created_at': FieldValue.serverTimestamp(),
            }),
            firestore.collection('notifications').add({
              'user_id': friendId,
              'title': 'New Expense',
              'body': '$myName added "$title" for ${AppConstants.currency}${_totalAmount.toInt()}',
              'type': 'new_expense',
              'created_at': FieldValue.serverTimestamp(),
              'is_read': false,
            }),
            NotificationService.sendPushNotification(
              recipientUid: friendId,
              title: 'New Expense',
              body: '$myName added "$title" for ${AppConstants.currency}${_totalAmount.toInt()}',
              data: {'type': 'new_expense'},
            ),
            Future.delayed(const Duration(milliseconds: 300)),
          ]);
        } else {
          await firestore.collection('expenses').doc(widget.expense!.id).update({
            'title': title,
            'amount': _totalAmount,
            'is_split': _isSplit,
          });
        }
        
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expense != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Added base bottom padding
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              isEdit ? 'Edit Expense' : 'Add Expense',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: AppConstants.currency,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !_isLoading,
                ),
                if (_amountController.text.contains(','))
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Total: ${AppConstants.currency}${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Split 50/50'),
                  value: _isSplit,
                  onChanged: _isLoading ? null : (value) => setState(() => _isSplit = value),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Adjusted spacing
          if (_isLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator()))
          else
            HoldToConfirmButton(
              onConfirm: _saveExpense,
              text: isEdit ? 'Hold to Update' : 'Tap and hold to post',
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12), // Safe area bottom padding
        ],
      ),
    );
  }
}
