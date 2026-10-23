import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/currency.dart';
import '../models/summary_period.dart';
import '../providers/summary_providers.dart';
import '../utils/money_format.dart';
import 'analytics_screen.dart';
import 'export_screen.dart';
import 'history_screen.dart';
import 'quick_add_screen.dart';

enum DashboardCurrencyFilter {
  lak,
  thb,
  usd,
  all,
}

final dashboardCurrencyFilterProvider = StateProvider<DashboardCurrencyFilter>(
  (ref) => DashboardCurrencyFilter.all,
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _currencies = [
    Currency.LAK,
    Currency.THB,
    Currency.USD,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(dashboardCurrencyFilterProvider);
    final visibleCurrencies = switch (selectedFilter) {
      DashboardCurrencyFilter.lak => const [Currency.LAK],
      DashboardCurrencyFilter.thb => const [Currency.THB],
      DashboardCurrencyFilter.usd => const [Currency.USD],
      DashboardCurrencyFilter.all => _currencies,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('TriWallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AnalyticsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('ວິເຄາະ'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('ປະຫວັດ'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExportScreen(),
                ),
              );
            },
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Export'),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<DashboardCurrencyFilter>(
              segments: const [
                ButtonSegment(
                  value: DashboardCurrencyFilter.lak,
                  label: Text('LAK'),
                ),
                ButtonSegment(
                  value: DashboardCurrencyFilter.thb,
                  label: Text('THB'),
                ),
                ButtonSegment(
                  value: DashboardCurrencyFilter.usd,
                  label: Text('USD'),
                ),
                ButtonSegment(
                  value: DashboardCurrencyFilter.all,
                  label: Text('ALL'),
                ),
              ],
              selected: {selectedFilter},
              onSelectionChanged: (selection) {
                ref.read(dashboardCurrencyFilterProvider.notifier).state =
                    selection.first;
              },
            ),
          ),
          const SizedBox(height: 16),
          for (final currency in visibleCurrencies)
            _CurrencySummaryCard(
              key: ValueKey(currency),
              currency: currency,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const QuickAddScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('ເພີ່ມລາຍການ'),
      ),
    );
  }
}

class _CurrencySummaryCard extends ConsumerWidget {
  const _CurrencySummaryCard({
    required this.currency,
    super.key,
  });

  final Currency currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(
      summaryProvider((
        currency: currency,
        period: SummaryPeriod.currentMonth,
      )),
    );
    final allTime = ref.watch(
      summaryProvider((
        currency: currency,
        period: SummaryPeriod.allTime,
      )),
    );

    if (currentMonth.isLoading || allTime.isLoading) {
      return const Card(
        child: SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final error = currentMonth.error ?? allTime.error;
    if (error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Unable to load ${currency.name} summary: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    final monthSummary = currentMonth.requireValue;
    final allTimeSummary = allTime.requireValue;
    final isEmpty = allTimeSummary.income == 0 && allTimeSummary.expense == 0;
    final currencyLabel = switch (currency) {
      Currency.LAK => '💰 LAK Balance',
      Currency.THB => '💵 THB Balance',
      Currency.USD => '💲 USD Balance',
    };
    final laoCaption = switch (currency) {
      Currency.LAK => 'ລາຍຮັບ LAK - ລາຍຈ່າຍ LAK',
      Currency.THB => 'ລາຍຮັບ THB - ລາຍຈ່າຍ THB',
      Currency.USD => 'ລາຍຮັບ USD - ລາຍຈ່າຍ USD',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currencyLabel, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(laoCaption),
            const SizedBox(height: 12),
            Text(
              formatMoney(monthSummary.balance, currency),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: monthSummary.balance < 0 ? Colors.red : null,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'ຍອດຄົງເຫຼືອລວມ: '
              '${formatMoney(allTimeSummary.balance, currency)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: allTimeSummary.balance < 0 ? Colors.red : null,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'ລາຍຮັບທັງໝົດ: '
              '${formatMoney(monthSummary.income, currency)}',
            ),
            Text(
              'ລາຍຈ່າຍທັງໝົດ: '
              '${formatMoney(monthSummary.expense, currency)}',
            ),
            if (isEmpty) ...[
              const SizedBox(height: 12),
              const Text('ຍັງບໍ່ມີລາຍການ'),
            ],
          ],
        ),
      ),
    );
  }
}
