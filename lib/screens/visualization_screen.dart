import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../viewmodels/visualization_viewmodel.dart';
import '../utils/format_helper.dart';
import '../utils/constants.dart';

class VisualizationScreen extends StatefulWidget {
  const VisualizationScreen({super.key});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisualizationViewModel>().loadData();
    });
  }

  Future<void> _selectPeriod(VisualizationViewModel viewModel) async {
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

  List<PieChartSectionData> _getPieChartSections(
      VisualizationViewModel viewModel) {
    if (viewModel.categoryData.isEmpty) return [];

    final total = viewModel.getTotalAmount();
    int i = 0;
    return viewModel.categoryData.entries.map((entry) {
      final isTouched = i == viewModel.touchedIndex;
      final fontSize = isTouched ? 18.0 : 12.0;
      final radius = isTouched ? 80.0 : 70.0;
      final percentage = (entry.value / total * 100);

      final section = PieChartSectionData(
        value: entry.value,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        color: AppConstants.categoryColors[entry.key] ?? Colors.grey,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      i++;
      return section;
    }).toList();
  }

  // Helper to get consecutive days based on ViewModel setting
  List<DateTime> _getChartDates(VisualizationViewModel viewModel) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(
        viewModel.barChartDays,
        (index) => today
            .subtract(Duration(days: (viewModel.barChartDays - 1) - index)));
  }

  List<BarChartGroupData> _getBarGroups(
      VisualizationViewModel viewModel, ColorScheme colorScheme) {
    final chartDates = _getChartDates(viewModel);
    final List<BarChartGroupData> groups = [];

    double maxVal = 0;
    for (var date in chartDates) {
      final val =
          viewModel.dailyData[DateTime(date.year, date.month, date.day)] ?? 0;
      if (val > maxVal) maxVal = val;
    }
    // Set a minimum ceiling for background rods
    final ceiling = maxVal > 0 ? maxVal * 1.2 : 100000.0;

    for (int i = 0; i < chartDates.length; i++) {
      final date = chartDates[i];
      // Normalize date to remove time parts for matching
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final value = viewModel.dailyData[normalizedDate] ?? 0;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: value > 0
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: viewModel.barChartDays > 14
                  ? 6
                  : (viewModel.barChartDays > 7 ? 10 : 16),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: ceiling,
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<VisualizationViewModel>();
    final total = viewModel.getTotalAmount();
    final chartDates = _getChartDates(viewModel);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analisis Grafik',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => viewModel.loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Summary Card
                    Card(
                      elevation: 0,
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onPrimaryContainer
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      FormatHelper.formatCurrency(total),
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton.filledTonal(
                                  onPressed: () => _selectPeriod(viewModel),
                                  icon: const Icon(Icons.date_range_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.surface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 14, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    viewModel.selectedPeriod == 'Custom' &&
                                            viewModel.customDateRange != null
                                        ? '${FormatHelper.formatDate(viewModel.customDateRange!.start)} - ${FormatHelper.formatDate(viewModel.customDateRange!.end)}'
                                        : 'Periode: ${viewModel.selectedPeriod}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (viewModel.categoryData.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          child: Column(
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 80,
                                color: colorScheme.outlineVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada data untuk periode ini',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // 1. Daily Trend Bar Chart
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.bar_chart_rounded,
                                        size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tren Pengeluaran',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                // Show selected days count
                                Text(
                                  '${viewModel.barChartDays} Hari',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Period Selector for Bar Chart - Full width to prevent overlap
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment(
                                      value: 7, label: Text('7 Hari')),
                                  ButtonSegment(
                                      value: 14, label: Text('14 Hari')),
                                  ButtonSegment(
                                      value: 30, label: Text('30 Hari')),
                                ],
                                selected: {viewModel.barChartDays},
                                onSelectionChanged: (Set<int> newSelection) {
                                  viewModel.setBarChartDays(newSelection.first);
                                },
                                style: SegmentedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 240,
                        padding: const EdgeInsets.only(right: 16, left: 8),
                        child: BarChart(
                          BarChartData(
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor:
                                    colorScheme.surfaceContainerHighest,
                                tooltipRoundedRadius: 8,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  final date = chartDates[groupIndex];
                                  return BarTooltipItem(
                                    '${date.day}/${date.month}\n${FormatHelper.formatCurrency(rod.toY)}',
                                    TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  );
                                },
                              ),
                            ),
                            barGroups: _getBarGroups(viewModel, colorScheme),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index < 0 ||
                                        index >= chartDates.length) {
                                      return const Text('');
                                    }

                                    // Logic to decide which labels to show
                                    bool showLabel = false;
                                    if (viewModel.barChartDays <= 7) {
                                      showLabel = true;
                                    } else if (viewModel.barChartDays <= 14) {
                                      showLabel = index % 2 == 0;
                                    } else {
                                      showLabel = index % 5 == 0;
                                    }

                                    // Always show the last date
                                    if (index == chartDates.length - 1)
                                      showLabel = true;

                                    if (!showLabel) return const Text('');

                                    final date = chartDates[index];
                                    final isToday =
                                        date.day == DateTime.now().day &&
                                            date.month == DateTime.now().month;
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 8,
                                      child: Text(
                                        isToday
                                            ? 'Hari Ini'
                                            : '${date.day}/${date.month}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: isToday
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isToday
                                              ? colorScheme.primary
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 2. Category Distribution Pie Chart
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 20),
                        child: Row(
                          children: [
                            Icon(Icons.pie_chart_rounded,
                                size: 20, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Distribusi Kategori',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      viewModel.setTouchedIndex(-1);
                                      return;
                                    }
                                    viewModel.setTouchedIndex(pieTouchResponse
                                        .touchedSection!.touchedSectionIndex);
                                  },
                                ),
                                sections: _getPieChartSections(viewModel),
                                sectionsSpace: 4,
                                centerSpaceRadius: 60,
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  viewModel.categoryData.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Kategori',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 3. Category Details List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rincian Kategori',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${viewModel.categoryData.length} Kategori',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...viewModel.categoryData.entries.map((entry) {
                        final percentage = (entry.value / total * 100);
                        final color = AppConstants.categoryColors[entry.key] ??
                            Colors.grey;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      AppConstants.categoryIcons[entry.key],
                                      color: color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    FormatHelper.formatCurrency(entry.value),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  color: color,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 100),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
