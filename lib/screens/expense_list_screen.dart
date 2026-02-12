import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../viewmodels/expense_list_viewmodel.dart';
import '../viewmodels/summary_viewmodel.dart';
import '../viewmodels/visualization_viewmodel.dart';
import '../utils/format_helper.dart';
import '../utils/constants.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseListViewModel>().loadExpenses();
    });
  }

  Future<void> _selectPeriod(ExpenseListViewModel viewModel) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Pilih Periode'),
          children: AppConstants.periods.map((period) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, period),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(period),
              ),
            );
          }).toList(),
        );
      },
    );

    if (!mounted) return;

    if (selected != null) {
      if (selected == 'Custom') {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: viewModel.customDateRange,
        );

        if (picked != null) {
          viewModel.setPeriod(selected, customRange: picked);
        }
      } else {
        viewModel.setPeriod(selected);
      }
    }
  }

  void _refreshAllData() {
    if (!mounted) return;
    context.read<ExpenseListViewModel>().loadExpenses();
    context.read<SummaryViewModel>().loadData();
    context.read<VisualizationViewModel>().loadData();
  }

  Future<void> _deleteExpense(
      ExpenseListViewModel viewModel, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Transaksi'),
          content:
              Text('Yakin ingin menghapus pengeluaran "${expense.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed == true) {
      final success = await viewModel.deleteExpense(expense.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
        _refreshAllData();
      }
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(expense: expense),
      ),
    );

    if (result == true && mounted) {
      _refreshAllData();
    }
  }

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );

    if (result == true && mounted) {
      _refreshAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<ExpenseListViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Pengeluaran',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              FormatHelper.formatCurrency(
                                  viewModel.getTotalAmount()),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        IconButton.filledTonal(
                          onPressed: () => _selectPeriod(viewModel),
                          icon: const Icon(Icons.date_range_rounded),
                          tooltip: 'Pilih Periode',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          viewModel.selectedPeriod == 'Custom' &&
                                  viewModel.customDateRange != null
                              ? '${FormatHelper.formatDate(viewModel.customDateRange!.start)} - ${FormatHelper.formatDate(viewModel.customDateRange!.end)}'
                              : 'Periode: ${viewModel.selectedPeriod}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 80,
                              color: colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada transaksi',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Coba pilih periode lain atau tambah data',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => viewModel.loadExpenses(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: viewModel.filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = viewModel.filteredExpenses[index];
                            final categoryColor =
                                AppConstants.categoryColors[expense.category] ??
                                    Colors.grey;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Dismissible(
                                key: Key(expense.id.toString()),
                                background: _buildDismissBackground(
                                  alignment: Alignment.centerLeft,
                                  color: Colors.blue.shade400,
                                  icon: Icons.edit_rounded,
                                ),
                                secondaryBackground: _buildDismissBackground(
                                  alignment: Alignment.centerRight,
                                  color: Colors.red.shade400,
                                  icon: Icons.delete_rounded,
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    await _deleteExpense(viewModel, expense);
                                    return false;
                                  } else {
                                    _editExpense(expense);
                                    return false;
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withValues(
                                            alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        AppConstants
                                            .categoryIcons[expense.category],
                                        color: categoryColor,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      expense.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          '${expense.category} • ${FormatHelper.formatDate(expense.date)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (expense.notes != null &&
                                            expense.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            expense.notes!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.7),
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Text(
                                      FormatHelper.formatCurrency(
                                          expense.amount),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    onTap: () => _editExpense(expense),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        elevation: 6,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDismissBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}
