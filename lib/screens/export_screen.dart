import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/currency.dart';
import '../models/wallet_transaction.dart';
import '../providers/summary_providers.dart';
import '../services/export_service.dart';
import '../utils/date_format.dart';

enum _ExportCurrency {
  all,
  lak,
  thb,
  usd,
}

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  _ExportCurrency _selectedCurrency = _ExportCurrency.all;
  late DateTime _from;
  late DateTime _to;
  final ExportService _exportService = ExportService();

  Currency? get _currency => switch (_selectedCurrency) {
        _ExportCurrency.all => null,
        _ExportCurrency.lak => Currency.LAK,
        _ExportCurrency.thb => Currency.THB,
        _ExportCurrency.usd => Currency.USD,
      };

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _from = DateTime(today.year, today.month);
    _to = DateTime(today.year, today.month, today.day);
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionHistoryProvider(_currency));
    final validRange = !_from.isAfter(_to);

    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<_ExportCurrency>(
            initialValue: _selectedCurrency,
            decoration: const InputDecoration(labelText: 'ສະກຸນເງິນ'),
            items: const [
              DropdownMenuItem(
                value: _ExportCurrency.all,
                child: Text('ALL'),
              ),
              DropdownMenuItem(
                value: _ExportCurrency.lak,
                child: Text('LAK'),
              ),
              DropdownMenuItem(
                value: _ExportCurrency.thb,
                child: Text('THB'),
              ),
              DropdownMenuItem(
                value: _ExportCurrency.usd,
                child: Text('USD'),
              ),
            ],
            onChanged: (selection) {
              if (selection != null) {
                setState(() => _selectedCurrency = selection);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectDate(isFrom: true),
                  child: Text('ຈາກ: ${formatDate(_from)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectDate(isFrom: false),
                  child: Text('ຫາ: ${formatDate(_to)}'),
                ),
              ),
            ],
          ),
          if (!validRange)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'ວັນເລີ່ມຕ້ອງບໍ່ຢູ່ຫຼັງວັນສິ້ນສຸດ',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          transactions.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Text(
              'ບໍ່ສາມາດໂຫຼດລາຍການໄດ້: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            data: (items) {
              final inRange = validRange
                  ? items
                      .where(
                        (transaction) => isTransactionInDateRange(
                          transaction,
                          from: _from,
                          to: _to,
                        ),
                      )
                      .toList(growable: false)
                  : const <WalletTransaction>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (inRange.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('ບໍ່ມີລາຍການໃນຊ່ວງນີ້'),
                    ),
                  FilledButton.icon(
                    onPressed:
                        inRange.isEmpty ? null : () => _exportCsv(inRange),
                    icon: const Icon(Icons.table_view),
                    label: const Text('Export CSV'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed:
                        inRange.isEmpty ? null : () => _exportPdf(inRange),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate({required bool isFrom}) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (!mounted || selectedDate == null) {
      return;
    }
    setState(() {
      if (isFrom) {
        _from = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
      } else {
        _to = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      }
    });
  }

  Future<void> _exportCsv(List<WalletTransaction> transactions) async {
    try {
      final file = await _exportService.saveCsv(
        transactions,
        currency: _currency,
        from: _from,
        to: _to,
      );
      _showMessage('CSV ບັນທຶກສຳເລັດ: ${file.path}');
    } catch (error) {
      _showMessage('ສົ່ງອອກ CSV ບໍ່ສຳເລັດ: $error', isError: true);
    }
  }

  Future<void> _exportPdf(List<WalletTransaction> transactions) async {
    try {
      final file = await _exportService.savePdf(
        context,
        transactions,
        currency: _currency,
        from: _from,
        to: _to,
      );
      _showMessage('PDF ບັນທຶກສຳເລັດ: ${file.path}');
    } catch (error) {
      _showMessage('ສົ່ງອອກ PDF ບໍ່ສຳເລັດ: $error', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }
}
