import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';
import '../utils/format_helper.dart';

class ExpenseListViewModel extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  String _selectedPeriod = 'Bulan Ini';
  DateTimeRange? _customDateRange;

  // Getters
  List<Expense> get filteredExpenses => _filteredExpenses;
  bool get isLoading => _isLoading;
  String get selectedPeriod => _selectedPeriod;
  DateTimeRange? get customDateRange => _customDateRange;

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final expenses = await DatabaseHelper.instance.readAllExpenses();
      _expenses = expenses;
      _filterExpenses();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _filterExpenses() {
    if (_selectedPeriod == 'Custom' && _customDateRange == null) {
      _filteredExpenses = List.from(_expenses);
    } else {
      final dateRange = _selectedPeriod == 'Custom'
          ? _customDateRange!
          : FormatHelper.getDateRange(_selectedPeriod);

      _filteredExpenses = _expenses.where((expense) {
        return expense.date
                .isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    // Sort by date descending
    _filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
  }

  void setPeriod(String period, {DateTimeRange? customRange}) {
    _selectedPeriod = period;
    _customDateRange = customRange;
    _filterExpenses();
    notifyListeners();
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await DatabaseHelper.instance.deleteExpense(id);
      await loadExpenses();
      return true;
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      return false;
    }
  }

  double getTotalAmount() {
    return _filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
  }
}
