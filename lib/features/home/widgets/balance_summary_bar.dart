import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';
import 'package:hisab/features/home/providers/expense_provider.dart';
import 'package:hisab/features/home/providers/friend_provider.dart';
import 'package:hisab/core/constants.dart';
import 'settlement_sheet.dart';

class BalanceSummaryBar extends ConsumerWidget {
  const BalanceSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);
    final user = ref.watch(currentUserProvider);
    final friendAsync = ref.watch(friendProvider);
    
    Color textColor;
    Color bgColor;
    String text;
    String myName = user?.displayName ?? 'You';
    String friendName = friendAsync.value?['full_name'] ?? 'Someone';
    
    if (balance > 0) {
      textColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.1);
      text = '$myName will get ${AppConstants.currency}${balance.toInt()}';
    } else if (balance < 0) {
      textColor = AppColors.alert;
      bgColor = AppColors.alert.withValues(alpha: 0.1);
      text = '$friendName will get ${AppConstants.currency}${balance.abs().toInt()}';
    } else {
      textColor = AppColors.textSecondary;
      bgColor = Theme.of(context).brightness == Brightness.light
          ? AppColors.primaryLight
          : Colors.grey[900]!;
      text = 'You’re all settled up';
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => const SettlementSheet(),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
