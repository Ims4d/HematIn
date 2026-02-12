import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/format_helper.dart';

class VisualizationViewModel extends ChangeNotifier {
  String _selectedPeriod = 'Bulan Ini';
  DateTimeRange? _customDateRange;
  Map<String, double> _categoryData = {};
  Map<DateTime, double> _dailyData = {};
  bool _isLoading = true;
  int _touchedIndex = -1;
  int _barChartDays = 7;

  // Getters
  String get selectedPeriod => _selectedPeriod;
  DateTimeRange? get customDateRange => _customDateRange;
  Map<String, double> get categoryData => _categoryData;
  Map<DateTime, double> get dailyData => _dailyData;
  bool get isLoading => _isLoading;
  int get touchedIndex => _touchedIndex;
  int get barChartDays => _barChartDays;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dateRange = _selectedPeriod == 'Custom' && _customDateRange != null
          ? _customDateRange!
          : FormatHelper.getDateRange(_selectedPeriod);

      _categoryData = await DatabaseHelper.instance
          .getExpensesByCategory(dateRange.start, dateRange.end);
          
      _dailyData = await DatabaseHelper.instance
          .getDailyExpenses(dateRange.start, dateRange.end);
    } catch (e) {
      debugPrint('Error loading visualization data: $e');
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

  void setBarChartDays(int days) {
    _barChartDays = days;
    notifyListeners();
  }

  void setTouchedIndex(int index) {
    _touchedIndex = index;
    notifyListeners();
  }

  double getTotalAmount() {
    return _categoryData.values.fold(0, (sum, amount) => sum + amount);
  }
}
