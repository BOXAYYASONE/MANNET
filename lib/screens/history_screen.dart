import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/currency.dart';
import '../models/transaction_type.dart';
import '../models/wallet_transaction.dart';
import '../providers/summary_providers.dart';
import '../utils/date_format.dart';
import '../utils/money_format.dart';

enum _HistoryCurrencyFilter {
  lak,
  thb,
  usd,
  all,
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryCurrencyFilter _filter = _HistoryCurrencyFilter.all;

  Currency? get _currency => switch (_filter) {
        _HistoryCurrencyFilter.lak => Currency.LAK,
        _HistoryCurrencyFilter.thb => Currency.THB,
        _HistoryCurrencyFilter.usd => Currency.USD,
        _HistoryCurrencyFilter.all => null,
      };

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionHistoryProvider(_currency));

    return Scaffold(
      appBar: AppBar(title: const Text('ປະຫວັດລາຍການ')),
      body: Column(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_HistoryCurrencyFilter>(
              segments: const [
                ButtonSegment(
                  value: _HistoryCurrencyFilter.lak,
                  label: Text('LAK'),
                ),
                ButtonSegment(
                  value: _HistoryCurrencyFilter.thb,
                  label: Text('THB'),
                ),
                ButtonSegment(
                  value: _HistoryCurrencyFilter.usd,
                  label: Text('USD'),
                ),
                ButtonSegment(
                  value: _HistoryCurrencyFilter.all,
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
            child: transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'ບໍ່ສາມາດໂຫຼດປະຫວັດໄດ້: $error',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('ຍັງບໍ່ມີລາຍການ'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _TransactionTile(transaction: items[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = formatDate(transaction.date);
    final type = switch (transaction.type) {
      TransactionType.income => 'ຮັບ',
      TransactionType.expense => 'ຈ່າຍ',
    };

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context, ref),
      child: ListTile(
        title: Text(transaction.category),
        subtitle: Text('$type · $date'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(transaction.currency.name),
            Text(
              formatMoney(transaction.amount, transaction.currency),
              style: TextStyle(
                color: transaction.amount < 0 ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ລຶບລາຍການ?'),
        content: const Text('ທ່ານແນ່ໃຈບໍ່ວ່າຈະລຶບລາຍການນີ້?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ຍົກເລີກ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ລຶບ'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return false;
    }

    try {
      await ref.read(transactionDeleteProvider.notifier).delete(
            transaction.id,
          );
      return true;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ລຶບບໍ່ສຳເລັດ: $error')),
        );
      }
      return false;
    }
  }
}
