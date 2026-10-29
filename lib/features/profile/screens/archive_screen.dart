import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab/features/home/providers/expense_provider.dart';
import 'package:hisab/features/home/widgets/expense_card.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';
import 'package:hisab/core/services/haptic_service.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
        centerTitle: true,
      ),
      body: expensesAsync.when(
        data: (expenses) {
          final archivedExpenses = expenses.where((e) => e.isArchived).toList();

          if (archivedExpenses.isEmpty) {
            return const Center(
              child: Text(
                'No archived expenses.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              HapticService.medium();
              await ref.refresh(expensesProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: archivedExpenses.length,
              itemBuilder: (context, index) {
                return ExpenseCard(
                  expense: archivedExpenses[index],
                  currentUserId: user?.uid ?? '',
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
