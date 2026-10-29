import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:hisab/features/home/providers/expense_provider.dart';
import 'package:hisab/features/home/providers/filter_provider.dart';
import 'package:hisab/features/home/providers/friend_provider.dart';
import 'package:hisab/features/home/models/expense_model.dart';
import 'package:hisab/features/home/widgets/balance_summary_bar.dart';
import 'package:hisab/features/home/widgets/expense_card.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';
import 'package:hisab/core/constants.dart';

import 'package:hisab/core/services/haptic_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(expenseFilterProvider);
    _pageController = PageController(initialPage: currentFilter.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final user = ref.watch(currentUserProvider);
    final currentFilter = ref.watch(expenseFilterProvider);
    final friendAsync = ref.watch(friendProvider);

    // Sync PageController if filter changes from elsewhere (like tapping a chip)
    if (_pageController.hasClients && _pageController.page?.round() != currentFilter.index) {
      _pageController.animateToPage(
        currentFilter.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisab'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const BalanceSummaryBar(),
          _buildFilterBar(ref, user, friendAsync.value),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                HapticService.light();
                ref.read(expenseFilterProvider.notifier).state = ExpenseFilter.values[index];
              },
              children: ExpenseFilter.values.map((filter) {
                return _buildExpenseList(expensesAsync, filter, user, friendAsync.value);
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildExpenseList(AsyncValue<List<Expense>> expensesAsync, ExpenseFilter filter, User? user, Map<String, dynamic>? friend) {
    return expensesAsync.when(
      data: (expenses) {
        final filteredExpenses = expenses.where((e) {
          if (e.isArchived) return false;
          if (filter == ExpenseFilter.all) return true;
          
          final myName = user?.displayName?.toLowerCase() ?? '';
          final friendName = friend?['full_name']?.toString().toLowerCase() ?? '';
          
          if (filter == ExpenseFilter.samir) {
            String? targetId;
            if (myName.contains('sk') || myName.contains('samir')) {
              targetId = user?.uid;
            } else if (friendName.contains('sk') || friendName.contains('samir')) {
              targetId = friend?['id'];
            }
            return targetId != null && e.paidBy == targetId;
          }
          if (filter == ExpenseFilter.karjan) {
            String? targetId;
            if (myName.contains('kd') || myName.contains('karjan')) {
              targetId = user?.uid;
            } else if (friendName.contains('kd') || friendName.contains('karjan')) {
              targetId = friend?['id'];
            }
            return targetId != null && e.paidBy == targetId;
          }
          return true;
        }).toList();

        if (filteredExpenses.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              HapticService.medium();
              await ref.refresh(expensesProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text('No expenses found for this filter.')),
              ],
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
            itemCount: filteredExpenses.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                key: ValueKey(filteredExpenses[index].id),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: ExpenseCard(
                  expense: filteredExpenses[index],
                  currentUserId: user?.uid ?? '',
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Connection issue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We are having trouble connecting to the server. Please check your internet or try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    HapticService.light();
                    await ref.refresh(expensesProvider.future);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Now'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(WidgetRef ref, User? user, Map<String, dynamic>? friend) {
    final currentFilter = ref.watch(expenseFilterProvider);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          _filterBox(ref, 'All', ExpenseFilter.all, currentFilter == ExpenseFilter.all),
          const SizedBox(width: 8),
          _filterBox(ref, 'Samir', ExpenseFilter.samir, currentFilter == ExpenseFilter.samir),
          const SizedBox(width: 8),
          _filterBox(ref, 'Karjan', ExpenseFilter.karjan, currentFilter == ExpenseFilter.karjan),
        ],
      ),
    );
  }

  Widget _filterBox(WidgetRef ref, String label, ExpenseFilter filter, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          ref.read(expenseFilterProvider.notifier).state = filter;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
