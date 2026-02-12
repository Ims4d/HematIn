import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';

class AddExpenseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> saveExpense(Expense expense, {bool isUpdate = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isUpdate) {
        await DatabaseHelper.instance.updateExpense(expense);
      } else {
        await DatabaseHelper.instance.createExpense(expense);
      }
      return true;
    } catch (e) {
      debugPrint('Error saving expense: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
