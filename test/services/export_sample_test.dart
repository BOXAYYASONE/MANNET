import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triwallet/models/currency.dart';
import 'package:triwallet/models/transaction_type.dart';
import 'package:triwallet/models/wallet_transaction.dart';
import 'package:triwallet/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('generates sample PDF and ALL-currency CSV files for debugging',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          key: const ValueKey('pdf-capture-context'),
          builder: (_) => const SizedBox(),
        ),
      ),
    );
    final context =
        tester.element(find.byKey(const ValueKey('pdf-capture-context')));
    final transactions = [
      _transaction(
        id: 1,
        currency: Currency.LAK,
        amount: 250000,
        type: TransactionType.income,
        date: DateTime(2026, 9, 28),
        category: 'ລາຍຮັບ',
        note: 'ຍອດກ່ອນຊ່ວງລາຍງານ',
      ),
      _transaction(
        id: 2,
        currency: Currency.LAK,
        amount: 35000,
        type: TransactionType.expense,
        date: DateTime(2026, 10, 2),
        category: 'ອາຫານ',
        note: 'ຈ່າຍຄ່າເຂົ້າ',
      ),
      _transaction(
        id: 3,
        currency: Currency.LAK,
        amount: 150000,
        type: TransactionType.income,
        date: DateTime(2026, 10, 5),
        category: 'ລາຍຮັບ',
        note: 'ລາຍຮັບເດືອນຕຸລາ',
      ),
      _transaction(
        id: 4,
        currency: Currency.THB,
        amount: 125050,
        type: TransactionType.income,
        date: DateTime(2026, 10, 8),
        category: 'ລາຍຮັບ THB',
        note: 'ທົດສອບ 1250.50',
      ),
      _transaction(
        id: 5,
        currency: Currency.USD,
        amount: 2599,
        type: TransactionType.expense,
        date: DateTime(2026, 11, 15),
        category: 'ຄ່າເດີນທາງ',
        note: 'ລາຍຈ່າຍເດືອນພະຈິກ',
      ),
    ];
    final from = DateTime(2026, 10, 1);
    final to = DateTime(2026, 11, 30);
    final service = ExportService();
    final csv = service.exportCsv(transactions, from: from, to: to);
    final directory = Directory('build');
    final csvFile = File(
      'build${Platform.pathSeparator}sample_transactions_2026-10-01_2026-11-30.csv',
    );
    final pdfFile = File(
      'build${Platform.pathSeparator}sample_transactions_2026-10-01_2026-11-30.pdf',
    );
    await tester.runAsync(() async {
      await directory.create(recursive: true);
      await csvFile.writeAsString(csv, flush: true);
    });
    final pdfFuture = service.buildPdf(
      context,
      transactions,
      from: from,
      to: to,
    );
    final pdfBytes = await _pumpUntilComplete(tester, pdfFuture);
    await tester.runAsync(
      () => pdfFile.writeAsBytes(pdfBytes, flush: true),
    );

    expect(csv, contains('THB,1250.50'));
    expect(csv, contains('USD,25.99'));
    expect(csv, contains('ອາຫານ'));
    expect(csv, contains('ຈ່າຍຄ່າເຂົ້າ'));
    expect(csv, isNot(contains('ຍອດກ່ອນຊ່ວງລາຍງານ')));
    final csvLength = await tester.runAsync(csvFile.length);
    final pdfLength = await tester.runAsync(pdfFile.length);
    expect(csvLength, greaterThan(0));
    expect(pdfLength, greaterThan(0));
    expect(pdfPageCount(pdfBytes), 1);
  });
}

WalletTransaction _transaction({
  required int id,
  required Currency currency,
  required int amount,
  required TransactionType type,
  required DateTime date,
  required String category,
  required String note,
}) =>
    WalletTransaction()
      ..id = id
      ..currency = currency
      ..amount = amount
      ..type = type
      ..category = category
      ..date = date
      ..note = note;

Future<T> _pumpUntilComplete<T>(
  WidgetTester tester,
  Future<T> future,
) async {
  var completed = false;
  final result = future.whenComplete(() => completed = true);
  var pumps = 0;
  while (!completed) {
    if (pumps++ >= 120) {
      throw StateError('PDF page capture did not complete after 120 frames.');
    }
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  return result;
}
