import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/currency.dart';
import '../models/summary_period.dart';
import '../models/transaction_type.dart';
import '../models/wallet_transaction.dart';
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
    final historyCurrency = switch (selectedFilter) {
      DashboardCurrencyFilter.lak => Currency.LAK,
      DashboardCurrencyFilter.thb => Currency.THB,
      DashboardCurrencyFilter.usd => Currency.USD,
      DashboardCurrencyFilter.all => null,
    };
    final transactions = ref.watch(transactionHistoryProvider(historyCurrency));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/mannet_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MNCK',
              style: TextStyle(
                color: Color(0xFF17201D),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded),
          ),
          IconButton(
            tooltip: 'ເຮັດວຽກໃນໄລຍະຕໍ່ໄປ',
            onPressed: null,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text(
            'ພາບລວມປະຈຳວັນ',
            style: TextStyle(
              color: Color(0xFF8A918E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'ພາບລວມກະເປົາ',
                  style: TextStyle(
                    color: Color(0xFF17201D),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _UpToDate(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DashboardAction(
                  icon: Icons.bar_chart_rounded,
                  label: 'ວິເຄາະ',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AnalyticsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashboardAction(
                  icon: Icons.receipt_long_rounded,
                  label: 'ປະຫວັດ',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashboardAction(
                  icon: Icons.upload_file_rounded,
                  label: 'ສົ່ງອອກ',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ExportScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CurrencyFilter(
            selected: selectedFilter,
            onSelected: (value) {
              ref.read(dashboardCurrencyFilterProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: _WalletsHeading()),
              const Text(
                'ຍອດລວມທັງໝົດ',
                style: TextStyle(
                  color: Color(0xFF9AA09D),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final currency in visibleCurrencies)
            _CurrencySummaryCard(
              key: ValueKey(currency),
              currency: currency,
            ),
          const SizedBox(height: 10),
          const _RecentTransactionsHeading(),
          const SizedBox(height: 12),
          _RecentTransactions(transactions: transactions),
        ],
      ),
      bottomNavigationBar: const _DashboardBottomNavigation(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const QuickAddScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _RecentTransactionsHeading extends StatelessWidget {
  const _RecentTransactionsHeading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'ລາຍການຫຼ້າສຸດ',
            style: TextStyle(
              color: Color(0xFF17201D),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          'ກິດຈະກຳຫຼ້າສຸດ',
          style: TextStyle(
            color: Color(0xFF9AA09D),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.transactions});

  final AsyncValue<List<WalletTransaction>> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (transactions.hasError) {
      return const Text('Unable to load recent transactions');
    }
    final items = transactions.requireValue.take(5).toList();
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'No recent transactions',
          style: TextStyle(color: Color(0xFF8A918E)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _RecentTransactionRow(transaction: items[index]),
            if (index < items.length - 1)
              const Divider(
                height: 1,
                indent: 68,
                color: Color(0xFFEFEFED),
              ),
          ],
        ],
      ),
    );
  }
}

class _RecentTransactionRow extends StatelessWidget {
  const _RecentTransactionRow({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amount = formatMoney(transaction.amount.abs(), transaction.currency);
    final formattedAmount = '${isIncome ? '+' : '-'}$amount';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  (isIncome ? const Color(0xFF24B56A) : const Color(0xFFEF6C57))
                      .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color:
                  isIncome ? const Color(0xFF24B56A) : const Color(0xFFEF6C57),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF17201D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${transaction.currency.name}  •  '
                  '${transaction.date.day.toString().padLeft(2, '0')}/'
                  '${transaction.date.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFF9AA09D),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              color:
                  isIncome ? const Color(0xFF24B56A) : const Color(0xFFE5484D),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBottomNavigation extends StatelessWidget {
  const _DashboardBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BottomAppBar(
        color: Colors.white,
        elevation: 12,
        height: 76,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: true,
            ),
            _BottomNavItem(
              icon: Icons.analytics_outlined,
              label: 'Analytics',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AnalyticsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 58),
            _BottomNavItem(
              icon: Icons.receipt_long_outlined,
              label: 'History',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HistoryScreen(),
                  ),
                );
              },
            ),
            const _BottomNavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF24B56A) : const Color(0xFF8A918E);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpToDate extends StatelessWidget {
  const _UpToDate();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F7ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Color(0xFF24B56A), size: 8),
          SizedBox(width: 6),
          Text(
            'ອັບເດດແລ້ວ',
            style: TextStyle(
              color: Color(0xFF167F4A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7EAE8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: const Color(0xFF59615E)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF59615E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (label == 'ສົ່ງອອກ')
                const Opacity(
                  opacity: 0,
                  child: Text('Export'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyFilter extends StatelessWidget {
  const _CurrencyFilter({
    required this.selected,
    required this.onSelected,
  });

  final DashboardCurrencyFilter selected;
  final ValueChanged<DashboardCurrencyFilter> onSelected;

  static const _values = [
    (DashboardCurrencyFilter.lak, 'LAK'),
    (DashboardCurrencyFilter.thb, 'THB'),
    (DashboardCurrencyFilter.usd, 'USD'),
    (DashboardCurrencyFilter.all, 'ALL'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFED),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final value in _values)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelected(value.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == value.$1
                        ? const Color(0xFF24B56A)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value.$2,
                    style: TextStyle(
                      color: selected == value.$1
                          ? Colors.white
                          : const Color(0xFF747B78),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WalletsHeading extends StatelessWidget {
  const _WalletsHeading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ກະເປົາຂອງທ່ານ',
          style: TextStyle(
            color: Color(0xFF17201D),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 9),
        _CountBadge(),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 27,
      height: 27,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE9ECEA),
        shape: BoxShape.circle,
      ),
      child: const Text(
        '3',
        style: TextStyle(
          color: Color(0xFF59615E),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CurrencySummaryCard extends ConsumerStatefulWidget {
  const _CurrencySummaryCard({
    required this.currency,
    super.key,
  });

  final Currency currency;

  @override
  ConsumerState<_CurrencySummaryCard> createState() =>
      _CurrencySummaryCardState();
}

class _CurrencySummaryCardState extends ConsumerState<_CurrencySummaryCard> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final currency = widget.currency;
    final allTime = ref.watch(
      summaryProvider((
        currency: currency,
        period: SummaryPeriod.allTime,
      )),
    );

    if (allTime.isLoading) {
      return Container(
        height: 220,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (allTime.hasError) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          'Unable to load ${currency.name} summary: ${allTime.error}',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    final summary = allTime.requireValue;
    final currencyLabel = switch (currency) {
      Currency.LAK => 'LAK',
      Currency.THB => 'THB',
      Currency.USD => 'USD',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F7F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF0F9D7A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F7F1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  currencyLabel,
                  style: const TextStyle(
                    color: Color(0xFF0F9D7A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
                icon: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'ຍອດຄົງເຫຼືອທັງໝົດ',
            style: TextStyle(
              color: Color(0xFF8A918E),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _isBalanceVisible
                ? formatMoney(summary.balance, currency)
                : '••••••••',
            style: TextStyle(
              color: summary.balance < 0
                  ? const Color(0xFFE5484D)
                  : const Color(0xFF17201D),
              fontSize: 29,
              height: 1.1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE7EAE8)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  icon: Icons.south_west_rounded,
                  iconColor: const Color(0xFF24B56A),
                  label: 'ລາຍຮັບ',
                  amount: _isBalanceVisible
                      ? formatMoney(summary.income.abs(), currency)
                      : '••••',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStat(
                  icon: Icons.north_east_rounded,
                  iconColor: const Color(0xFFEF6C57),
                  label: 'ລາຍຈ່າຍ',
                  amount: _isBalanceVisible
                      ? formatMoney(summary.expense.abs(), currency)
                      : '••••',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A918E),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF17201D),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
