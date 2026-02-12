import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';
import '../utils/format_helper.dart';

class SummaryViewModel extends ChangeNotifier {
  String _selectedPeriod = 'Bulan Ini';
  DateTimeRange? _customDateRange;
  List<Expense> _expenses = [];
  Map<String, double> _categoryTotals = {};
  double _todayExpense = 0;
  double _weekExpense = 0;
  double _monthExpense = 0;
  double? _monthlyBudget;
  bool _isLoading = true;

  // Getters
  String get selectedPeriod => _selectedPeriod;
  DateTimeRange? get customDateRange => _customDateRange;
  List<Expense> get expenses => _expenses;
  Map<String, double> get categoryTotals => _categoryTotals;
  double get todayExpense => _todayExpense;
  double get weekExpense => _weekExpense;
  double get monthExpense => _monthExpense;
  double? get monthlyBudget => _monthlyBudget;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Get budget
      _monthlyBudget = await DatabaseHelper.instance.getMonthlyBudget();

      // Get totals
      _todayExpense = await DatabaseHelper.instance.getTotalExpense(
        today,
        today.add(const Duration(days: 1)),
      );

      _weekExpense = await DatabaseHelper.instance.getTotalExpense(
        startOfWeek,
        today.add(const Duration(days: 1)),
      );

      _monthExpense = await DatabaseHelper.instance.getTotalExpense(
        startOfMonth,
        endOfMonth,
      );

      final dateRange = _selectedPeriod == 'Custom' && _customDateRange != null
          ? _customDateRange!
          : FormatHelper.getDateRange(_selectedPeriod);

      _expenses = await DatabaseHelper.instance
          .readExpensesByDateRange(dateRange.start, dateRange.end);

      _categoryTotals = await DatabaseHelper.instance
          .getExpensesByCategory(dateRange.start, dateRange.end);

    } catch (e) {
      debugPrint('Error loading summary data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPeriod(String period, {DateTimeRange? customRange}) {
    _selectedPeriod = period;
    _customDateRange = customRange;
    loadData();
  }

  double getTotalAmount() {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  double getAveragePerDay() {
    if (_expenses.isEmpty) return 0;

    final dateRange = _selectedPeriod == 'Custom' && _customDateRange != null
        ? _customDateRange!
        : FormatHelper.getDateRange(_selectedPeriod);

    final days = dateRange.end.difference(dateRange.start).inDays + 1;
    return getTotalAmount() / days;
  }

  String getMostExpensiveCategory() {
    if (_categoryTotals.isEmpty) return '-';

    var maxEntry = _categoryTotals.entries.first;
    for (var entry in _categoryTotals.entries) {
      if (entry.value > maxEntry.value) {
        maxEntry = entry;
      }
    }
    return maxEntry.key;
  }

  double getBudgetPercentage() {
    if (_monthlyBudget == null || _monthlyBudget == 0) return 0;
    return (_monthExpense / _monthlyBudget!) * 100;
  }
}
