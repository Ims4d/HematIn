import 'package:flutter/material.dart';

class AppConstants {
  // Kategori pengeluaran
  static const List<String> expenseCategories = [
    'Makanan & Minuman',
    'Transportasi',
    'Belanja',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Tagihan',
    'Lainnya',
  ];

  // Warna untuk setiap kategori
  static const Map<String, Color> categoryColors = {
    'Makanan & Minuman': Colors.orange,
    'Transportasi': Colors.blue,
    'Belanja': Colors.purple,
    'Hiburan': Colors.pink,
    'Kesehatan': Colors.red,
    'Pendidikan': Colors.green,
    'Tagihan': Colors.teal,
    'Lainnya': Colors.grey,
  };

  // Icon untuk setiap kategori
  static const Map<String, IconData> categoryIcons = {
    'Makanan & Minuman': Icons.restaurant,
    'Transportasi': Icons.directions_car,
    'Belanja': Icons.shopping_bag,
    'Hiburan': Icons.movie,
    'Kesehatan': Icons.local_hospital,
    'Pendidikan': Icons.school,
    'Tagihan': Icons.receipt_long,
    'Lainnya': Icons.more_horiz,
  };

  // Periode untuk filter
  static const List<String> periods = [
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
    'Tahun Ini',
    'Custom',
  ];
}
