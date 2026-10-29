import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExpenseFilter { all, samir, karjan }

final expenseFilterProvider = StateProvider<ExpenseFilter>((ref) => ExpenseFilter.all);
