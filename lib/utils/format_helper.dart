import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FormatHelper {
  static String formatCurrency(double amount) {
    final format =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  static String formatDate(DateTime date) {
    final format = DateFormat('d MMMM yyyy', 'id_ID');
    return format.format(date);
  }

  static DateTimeRange getDateRange(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case 'Hari Ini':
        return DateTimeRange(start: today, end: today);
      case 'Kemarin':
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      case 'Minggu Ini':
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return DateTimeRange(start: startOfWeek, end: endOfWeek);
      case 'Bulan Ini':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case 'Tahun Ini':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        return DateTimeRange(start: startOfYear, end: endOfYear);
      default:
        // 'Semua'
        return DateTimeRange(
          start: DateTime(2000),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }
}
