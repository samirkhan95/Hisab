import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab/features/home/providers/expense_provider.dart';
import 'package:hisab/features/home/widgets/expense_card.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';
import 'package:hisab/core/constants.dart';

import 'package:hisab/core/services/haptic_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Expenses'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Results
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                final filteredExpenses = expenses.where((expense) {
                  return expense.title.toLowerCase().contains(_searchQuery);
                }).toList();

                if (_searchQuery.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Type to search for expenses',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredExpenses.isEmpty) {
                  return const Center(
                    child: Text('No matching expenses found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    return ExpenseCard(
                      expense: filteredExpenses[index],
                      currentUserId: user?.uid ?? '',
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),

          // Search Bar at the Bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 130), // Increased bottom padding to 130
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                HapticService.light();
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          HapticService.medium();
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.primary.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
