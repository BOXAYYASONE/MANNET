import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/currency.dart';
import '../providers/summary_providers.dart';
import '../repositories/transaction_repository.dart';
import '../utils/date_format.dart';
import '../utils/money_format.dart';

enum _AnalyticsCurrencyFilter {
  lak,
  thb,
  usd,
  all,
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  static const _currencies = [Currency.LAK, Currency.THB, Currency.USD];

  _AnalyticsCurrencyFilter _filter = _AnalyticsCurrencyFilter.all;

  List<Currency> get _visibleCurrencies => switch (_filter) {
        _AnalyticsCurrencyFilter.lak => const [Currency.LAK],
        _AnalyticsCurrencyFilter.thb => const [Currency.THB],
        _AnalyticsCurrencyFilter.usd => const [Currency.USD],
        _AnalyticsCurrencyFilter.all => _currencies,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ວິເຄາະ')),
      body: Column(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_AnalyticsCurrencyFilter>(
              segments: const [
                ButtonSegment(
                  value: _AnalyticsCurrencyFilter.lak,
                  label: Text('LAK'),
                ),
                ButtonSegment(
                  value: _AnalyticsCurrencyFilter.thb,
                  label: Text('THB'),
                ),
                ButtonSegment(
                  value: _AnalyticsCurrencyFilter.usd,
                  label: Text('USD'),
                ),
                ButtonSegment(
                  value: _AnalyticsCurrencyFilter.all,
                  label: Text('ALL'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final currency in _visibleCurrencies)
                  _CurrencyAnalyticsPanel(
                    key: ValueKey(currency),
                    currency: currency,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyAnalyticsPanel extends ConsumerWidget {
  const _CurrencyAnalyticsPanel({
    required this.currency,
    super.key,
  });

  final Currency currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider(currency));
    return analytics.when(
      loading: () => const Card(
        child: SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນວິເຄາະ ${currency.name}: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      data: (data) => _AnalyticsCharts(
        currency: currency,
        data: data,
      ),
    );
  }
}

class _AnalyticsCharts extends StatelessWidget {
  const _AnalyticsCharts({
    required this.currency,
    required this.data,
  });

  final Currency currency;
  final CurrencyAnalytics data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(
            currency.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (!data.hasTransactions)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('ຍັງບໍ່ມີລາຍການ')),
            ),
          ),
        _ExpensePieCard(
          currency: currency,
          expenses: data.expensesByCategory,
        ),
        _MonthlyBarCard(
          currency: currency,
          monthlyTotals: data.monthlyTotals,
        ),
      ],
    );
  }
}

class _ExpensePieCard extends StatelessWidget {
  const _ExpensePieCard({
    required this.currency,
    required this.expenses,
  });

  final Currency currency;
  final List<CategoryExpenseTotal> expenses;

  static const _colors = [
    Color(0xff1976d2),
    Color(0xffef6c00),
    Color(0xff388e3c),
    Color(0xff8e24aa),
    Color(0xffd81b60),
    Color(0xff00897b),
    Color(0xfff9a825),
    Color(0xff546e7a),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleExpenses =
        expenses.where((expense) => expense.amount > 0).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ລາຍຈ່າຍຕາມໝວດໝູ່',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (visibleExpenses.isEmpty)
              const SizedBox(
                height: 170,
                child: Center(child: Text('ບໍ່ມີລາຍຈ່າຍ')),
              )
            else ...[
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: [
                      for (var index = 0;
                          index < visibleExpenses.length;
                          index++)
                        PieChartSectionData(
                          value: visibleExpenses[index].amount.toDouble(),
                          color: _colors[index % _colors.length],
                          title: '',
                          radius: 82,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < visibleExpenses.length; index++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _colors[index % _colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(visibleExpenses[index].category)),
                      Text(
                        formatMoney(
                          visibleExpenses[index].amount,
                          currency,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarCard extends StatelessWidget {
  const _MonthlyBarCard({
    required this.currency,
    required this.monthlyTotals,
  });

  final Currency currency;
  final List<MonthlyTransactionTotals> monthlyTotals;

  @override
  Widget build(BuildContext context) {
    final maximum = monthlyTotals.fold<int>(
      0,
      (value, month) => math.max(
        value,
        math.max(month.income, month.expense),
      ),
    );
    final chartMaximum = maximum == 0 ? 1.0 : maximum.toDouble() * 1.2;
    final chartWidth = math.max(
      840.0,
      MediaQuery.sizeOf(context).width - 64,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ລາຍຮັບ ແລະ ລາຍຈ່າຍລາຍເດືອນ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: const [
                _ChartLegend(color: Color(0xff2e7d32), label: 'ລາຍຮັບ'),
                _ChartLegend(color: Color(0xffc62828), label: 'ລາຍຈ່າຍ'),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 280,
                child: BarChart(
                  BarChartData(
                    maxY: chartMaximum,
                    barGroups: [
                      for (var index = 0; index < monthlyTotals.length; index++)
                        BarChartGroupData(
                          x: index,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: monthlyTotals[index].income.toDouble(),
                              color: const Color(0xff2e7d32),
                              width: 10,
                              borderRadius: BorderRadius.zero,
                            ),
                            BarChartRodData(
                              toY: monthlyTotals[index].expense.toDouble(),
                              color: const Color(0xffc62828),
                              width: 10,
                              borderRadius: BorderRadius.zero,
                            ),
                          ],
                        ),
                    ],
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label = rodIndex == 0 ? 'ລາຍຮັບ' : 'ລາຍຈ່າຍ';
                          return BarTooltipItem(
                            '$label\n${formatMoney(rod.toY.round(), currency)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 96,
                          interval: chartMaximum / 4,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              formatMoney(value.round(), currency),
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= monthlyTotals.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                formatDate(monthlyTotals[index].month),
                                style: const TextStyle(fontSize: 9),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
