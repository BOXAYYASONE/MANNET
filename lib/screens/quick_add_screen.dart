import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/currency.dart';
import '../models/transaction_type.dart';
import '../models/wallet_transaction.dart';
import '../providers/summary_providers.dart';
import '../utils/date_format.dart';

class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();

  Currency _currency = Currency.LAK;
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(transactionSaveProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('ເພີ່ມລາຍການ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('ສະກຸນເງິນ'),
            const SizedBox(height: 8),
            SegmentedButton<Currency>(
              segments: const [
                ButtonSegment(value: Currency.LAK, label: Text('LAK')),
                ButtonSegment(value: Currency.THB, label: Text('THB')),
                ButtonSegment(value: Currency.USD, label: Text('USD')),
              ],
              selected: {_currency},
              onSelectionChanged: isSaving
                  ? null
                  : (selection) {
                      setState(() => _currency = selection.first);
                      final inputFormatter = _AmountInputFormatter(_currency);
                      _amountController.value = inputFormatter.formatEditUpdate(
                        TextEditingValue.empty,
                        _amountController.value,
                      );
                    },
            ),
            const SizedBox(height: 16),
            const Text('ປະເພດລາຍການ'),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('ຮັບ'),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('ຈ່າຍ'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: isSaving
                  ? null
                  : (selection) => setState(() => _type = selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              enabled: !isSaving,
              decoration: InputDecoration(
                labelText: 'ຈຳນວນເງິນ (${_currency.name})',
                hintText: _currency == Currency.LAK ? '0' : '0.00',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_AmountInputFormatter(_currency)],
              validator: (value) {
                final amount = _parseAmount(value ?? '', _currency);
                if (amount == null || amount <= 0) {
                  return _currency == Currency.LAK
                      ? 'ກະລຸນາໃສ່ຈຳນວນເງິນກີບທີ່ຫຼາຍກວ່າ 0'
                      : 'ກະລຸນາໃສ່ຈຳນວນເງິນທີ່ຖືກຕ້ອງ ແລະຫຼາຍກວ່າ 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              enabled: !isSaving,
              decoration: const InputDecoration(labelText: 'ໝວດໝູ່'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'ກະລຸນາໃສ່ໝວດໝູ່'
                  : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ວັນທີ'),
              subtitle: Text(
                formatDate(_date),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: isSaving ? null : _selectDate,
            ),
            TextFormField(
              controller: _noteController,
              enabled: !isSaving,
              decoration: const InputDecoration(labelText: 'ໝາຍເຫດ (ຖ້າມີ)'),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isSaving ? null : _save,
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ບັນທຶກ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() => _date = selectedDate);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = _parseAmount(_amountController.text, _currency);
    if (amount == null || amount <= 0) {
      return;
    }

    final transaction = WalletTransaction()
      ..currency = _currency
      ..amount = amount
      ..type = _type
      ..category = _categoryController.text.trim()
      ..date = _date
      ..note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

    try {
      await ref.read(transactionSaveProvider.notifier).save(transaction);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ບັນທຶກບໍ່ສຳເລັດ: $error')),
        );
      }
    }
  }
}

int? _parseAmount(String input, Currency currency) {
  final value = input.trim().replaceAll(',', '');
  if (currency == Currency.LAK) {
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return null;
    }
    return int.tryParse(value);
  }

  final parts = value.split('.');
  if (parts.length > 2 ||
      !RegExp(r'^\d*$').hasMatch(parts.first) ||
      (parts.length == 2 && !RegExp(r'^\d{0,2}$').hasMatch(parts[1]))) {
    return null;
  }

  final wholeUnits = BigInt.tryParse(parts.first.isEmpty ? '0' : parts.first);
  if (wholeUnits == null) {
    return null;
  }
  final fraction = (parts.length == 2 ? parts[1] : '').padRight(2, '0');
  final minorUnits = wholeUnits * BigInt.from(100) +
      BigInt.tryParse(fraction.isEmpty ? '0' : fraction)!;
  if (minorUnits > BigInt.from(0x7fffffffffffffff)) {
    return null;
  }
  return minorUnits.toInt();
}

class _AmountInputFormatter extends TextInputFormatter {
  _AmountInputFormatter(this.currency);

  final Currency currency;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final allowDecimal = currency != Currency.LAK;
    var raw = newValue.text.replaceAll(',', '');
    if (allowDecimal) {
      raw = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    } else {
      raw = raw.split('.').first.replaceAll(RegExp(r'[^0-9]'), '');
    }

    String whole;
    String fraction = '';
    var hasDecimal = false;
    if (allowDecimal && raw.contains('.')) {
      final decimalIndex = raw.indexOf('.');
      whole = raw.substring(0, decimalIndex);
      final enteredFraction = raw.substring(decimalIndex + 1).replaceAll(
            '.',
            '',
          );
      fraction = enteredFraction.length > 2
          ? enteredFraction.substring(0, 2)
          : enteredFraction;
      hasDecimal = true;
    } else {
      whole = raw;
    }

    if (whole.isEmpty && hasDecimal) {
      whole = '0';
    }
    final groupedWhole = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      if (index > 0 && (whole.length - index) % 3 == 0) {
        groupedWhole.write(',');
      }
      groupedWhole.write(whole[index]);
    }
    final formatted =
        groupedWhole.toString() + (hasDecimal ? '.$fraction' : '');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
