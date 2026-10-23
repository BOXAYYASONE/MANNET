import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triwallet/models/currency.dart';
import 'package:triwallet/models/transaction_type.dart';
import 'package:triwallet/models/wallet_transaction.dart';
import 'package:triwallet/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final start = DateTime(2026, 10, 1);
  final end = DateTime(2026, 10, 31);

  test('opening balance excludes transactions on or after range start', () {
    final reports = buildCurrencyReports(
      [
        _transaction(
          id: 1,
          currency: Currency.LAK,
          amount: 1000,
          type: TransactionType.income,
          date: DateTime(2026, 9, 30, 23, 59),
        ),
        _transaction(
          id: 2,
          currency: Currency.LAK,
          amount: 250,
          type: TransactionType.expense,
          date: start,
        ),
        _transaction(
          id: 3,
          currency: Currency.LAK,
          amount: 900,
          type: TransactionType.income,
          date: DateTime(2026, 10, 15),
        ),
      ],
      from: start,
      to: end,
    );

    expect(_report(reports, Currency.LAK).openingBalance, 1000);
  });

  test('running balance restarts per currency and excludes other currencies',
      () {
    final reports = buildCurrencyReports(
      [
        _transaction(
          id: 1,
          currency: Currency.LAK,
          amount: 1000,
          type: TransactionType.income,
          date: start,
        ),
        _transaction(
          id: 2,
          currency: Currency.THB,
          amount: 900,
          type: TransactionType.income,
          date: start,
        ),
        _transaction(
          id: 3,
          currency: Currency.LAK,
          amount: 200,
          type: TransactionType.expense,
          date: DateTime(2026, 10, 2),
        ),
      ],
      from: start,
      to: end,
    );

    expect(
      _report(reports, Currency.LAK)
          .rows
          .map((row) => row.runningBalance)
          .toList(),
      [1000, 800],
    );
    expect(
      _report(reports, Currency.THB)
          .rows
          .map((row) => row.runningBalance)
          .toList(),
      [900],
    );
    expect(_report(reports, Currency.USD).rows, isEmpty);
  });

  test('closing balance equals opening plus income minus expense', () {
    final reports = buildCurrencyReports(
      [
        _transaction(
          id: 1,
          currency: Currency.THB,
          amount: 800,
          type: TransactionType.income,
          date: DateTime(2026, 9, 30),
        ),
        _transaction(
          id: 2,
          currency: Currency.THB,
          amount: 500,
          type: TransactionType.income,
          date: start,
        ),
        _transaction(
          id: 3,
          currency: Currency.THB,
          amount: 250,
          type: TransactionType.expense,
          date: DateTime(2026, 10, 2),
        ),
        _transaction(
          id: 4,
          currency: Currency.LAK,
          amount: 9900,
          type: TransactionType.income,
          date: start,
        ),
      ],
      from: start,
      to: end,
    );
    final report = _report(reports, Currency.THB);

    expect(report.totalIncome, 500);
    expect(report.totalExpense, 250);
    expect(report.closingBalance, 1050);
    expect(
      report.closingBalance,
      report.openingBalance + report.totalIncome - report.totalExpense,
    );
  });

  testWidgets('PDF below 30 transactions contains no empty pages', (
    tester,
  ) async {
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
    final sampleTransactions = [
      for (var index = 0; index < 25; index++)
        _transaction(
          id: index + 1,
          currency: Currency.LAK,
          amount: 1500 + index,
          type: TransactionType.income,
          date: start.add(Duration(days: index)),
        ),
    ];
    final reports = buildCurrencyReports(
      sampleTransactions,
      from: start,
      to: end,
    );
    final layouts = buildPdfPageLayouts(
      reports,
      from: start,
      to: end,
      currencyLabel: 'ALL',
    );
    final pdfFuture = ExportService().buildPdf(
      context,
      sampleTransactions,
      from: start,
      to: end,
    );
    final bytes = await _pumpUntilComplete(tester, pdfFuture);

    expect(layouts, hasLength(2));
    expect(layouts.every((page) => page.hasVisibleContent), isTrue);
    expect(pdfPageCount(bytes), layouts.length);
    expect(
      layouts.expand((page) => page.rows).length,
      25,
    );
  });

  testWidgets('report contains one table and the expected title/date strings',
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
        amount: 5000,
        type: TransactionType.income,
        date: DateTime(2026, 10, 2),
      ),
    ];
    final pdfFuture = ExportService().buildPdf(
      context,
      transactions,
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 31),
    );
    final bytes = await _pumpUntilComplete(tester, pdfFuture);

    expect(pdfPageCount(bytes), 1);
    expect(ExportService.reportTitle, 'ລາຍງານລາຍຮັບລາຍຈ່າຍ');
    expect(
      ExportService.dateRangeLabel(DateTime(2026, 10, 1), DateTime(2026, 10, 31)),
      'ວັນທີ 01/10/2026 ຫາວັນທີ 31/10/2026',
    );
  });

  test('currency symbol appears after the number', () {
    expect(ExportService.formatPdfMoney(100000, Currency.LAK), '100,000₭');
    expect(ExportService.formatPdfMoney(125050, Currency.THB), '1,250.50 THB');
    expect(ExportService.formatPdfMoney(125050, Currency.USD), r'1,250.50 $');
  });

  test('exports ALL currencies to one CSV with plain amounts and dates', () {
    final csv = ExportService().exportCsv(
      [
        _transaction(
          id: 1,
          currency: Currency.LAK,
          amount: 1000,
          type: TransactionType.income,
          date: start,
        ),
        _transaction(
          id: 2,
          currency: Currency.THB,
          amount: 125050,
          type: TransactionType.income,
          date: DateTime(2026, 10, 2),
        ),
        _transaction(
          id: 3,
          currency: Currency.USD,
          amount: 999,
          type: TransactionType.expense,
          date: DateTime(2026, 11, 2),
        ),
        _transaction(
          id: 4,
          currency: Currency.LAK,
          amount: 400,
          type: TransactionType.expense,
          date: DateTime(2026, 9, 30),
        ),
      ],
      from: start,
      to: DateTime(2026, 11, 30),
    );

    expect(
      csv.split('\r\n').first,
      'Currency,Amount,Category,Type,Date,Note',
    );
    expect(csv, contains('LAK,1000,Food,income,01/10/2026,'));
    expect(csv, contains('THB,1250.50,Food,income,02/10/2026,'));
    expect(csv, contains('USD,9.99,Food,expense,02/11/2026,'));
    expect(csv, isNot(contains('30/09/2026')));
    expect(csv, isNot(contains('₭')));
    expect(csv, isNot(contains('฿')));
  });
}

CurrencyReport _report(List<CurrencyReport> reports, Currency currency) =>
    reports.singleWhere((report) => report.currency == currency);

WalletTransaction _transaction({
  required int id,
  required Currency currency,
  required int amount,
  required TransactionType type,
  required DateTime date,
}) =>
    WalletTransaction()
      ..id = id
      ..currency = currency
      ..amount = amount
      ..type = type
      ..category = 'Food'
      ..date = date;

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
