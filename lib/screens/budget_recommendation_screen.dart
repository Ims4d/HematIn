import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../utils/format_helper.dart';

class BudgetRecommendationScreen extends StatefulWidget {
  const BudgetRecommendationScreen({super.key});

  @override
  State<BudgetRecommendationScreen> createState() =>
      _BudgetRecommendationScreenState();
}

class _BudgetRecommendationScreenState
    extends State<BudgetRecommendationScreen> {
  final _budgetController = TextEditingController();
  double? _currentBudget;
  double _currentMonthExpense = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final budget = await DatabaseHelper.instance.getMonthlyBudget();
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final total = await DatabaseHelper.instance.getTotalExpense(
        startOfMonth,
        endOfMonth,
      );

      setState(() {
        _currentBudget = budget;
        _currentMonthExpense = total;
        if (budget != null) {
          _budgetController.text = budget.toStringAsFixed(0);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _saveBudget() async {
    final budgetText = _budgetController.text.trim();
    if (budgetText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah budget')),
      );
      return;
    }

    final budget = double.tryParse(budgetText);
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah budget tidak valid')),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.setMonthlyBudget(budget);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  double _getRemainingBudget() {
    if (_currentBudget == null) return 0;
    return _currentBudget! - _currentMonthExpense;
  }

  double _getBudgetPercentage() {
    if (_currentBudget == null || _currentBudget == 0) return 0;
    return (_currentMonthExpense / _currentBudget!) * 100;
  }

  String _getRecommendation() {
    if (_currentBudget == null) {
      return 'Tetapkan budget bulanan Anda untuk mendapatkan rekomendasi pengelolaan keuangan.';
    }

    final percentage = _getBudgetPercentage();
    final remaining = _getRemainingBudget();
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;
    final dailyBudget = remaining / daysRemaining;

    if (percentage >= 100) {
      return '⚠️ Anda telah melebihi budget bulanan! Sangat disarankan untuk mengurangi pengeluaran di sisa bulan ini.';
    } else if (percentage >= 90) {
      return '🔴 Budget Anda hampir habis (${percentage.toStringAsFixed(1)}%). Hanya tersisa ${FormatHelper.formatCurrency(remaining)}. Batasi pengeluaran hingga akhir bulan.';
    } else if (percentage >= 75) {
      return '🟡 Anda telah menggunakan ${percentage.toStringAsFixed(1)}% dari budget. Sisa ${FormatHelper.formatCurrency(remaining)}. Budget harian yang disarankan: ${FormatHelper.formatCurrency(dailyBudget)}';
    } else if (percentage >= 50) {
      return '🟢 Pengeluaran Anda ${percentage.toStringAsFixed(1)}% dari budget. Masih tersisa ${FormatHelper.formatCurrency(remaining)}. Jaga konsistensi! Budget harian: ${FormatHelper.formatCurrency(dailyBudget)}';
    } else {
      return '✅ Pengelolaan keuangan Anda sangat baik! Baru ${percentage.toStringAsFixed(1)}% dari budget terpakai. Tersisa ${FormatHelper.formatCurrency(remaining)}. Budget harian: ${FormatHelper.formatCurrency(dailyBudget)}';
    }
  }

  Color _getStatusColor() {
    final percentage = _getBudgetPercentage();
    if (percentage >= 100) return Colors.red[700]!;
    if (percentage >= 90) return Colors.red;
    if (percentage >= 75) return Colors.orange;
    if (percentage >= 50) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekomendasi Budget'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Budget Input
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Budget Bulanan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _budgetController,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah Budget',
                              hintText: 'Contoh: 5000000',
                              border: OutlineInputBorder(),
                              prefixText: 'Rp ',
                              prefixIcon: Icon(Icons.account_balance_wallet),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveBudget,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Simpan Budget'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Status
                  if (_currentBudget != null) ...[
                    Card(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Status Bulan Ini',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_getBudgetPercentage().toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Budget:',
                              FormatHelper.formatCurrency(_currentBudget!),
                              Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Terpakai:',
                              FormatHelper.formatCurrency(_currentMonthExpense),
                              Colors.red,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Sisa:',
                              FormatHelper.formatCurrency(
                                  _getRemainingBudget()),
                              Colors.green,
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _getBudgetPercentage() / 100,
                                minHeight: 12,
                                backgroundColor: Colors.grey[300],
                                color: _getStatusColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recommendation
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: Colors.amber[700],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Rekomendasi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getRecommendation(),
                              style: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tips
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Tips Pengelolaan Keuangan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTip('Catat setiap pengeluaran secara rutin'),
                            _buildTip(
                                'Prioritaskan kebutuhan daripada keinginan'),
                            _buildTip('Sisihkan minimal 10-20% untuk tabungan'),
                            _buildTip('Review pengeluaran setiap minggu'),
                            _buildTip(
                                'Batasi pengeluaran impulsif atau tidak terencana'),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tetapkan budget bulanan Anda',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Untuk mendapatkan rekomendasi dan monitoring pengeluaran',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
