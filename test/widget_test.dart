import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:triwallet/main.dart';
import 'package:triwallet/models/currency.dart';
import 'package:triwallet/models/summary_period.dart';
import 'package:triwallet/models/transaction_type.dart';
import 'package:triwallet/models/wallet_transaction.dart';
import 'package:triwallet/providers/summary_providers.dart';
import 'package:triwallet/repositories/transaction_repository.dart';
import 'package:triwallet/screens/analytics_screen.dart';
import 'package:triwallet/screens/history_screen.dart';
import 'package:triwallet/screens/quick_add_screen.dart';
import 'package:triwallet/utils/date_format.dart';

void main() {
  testWidgets('TriWallet app renders the dashboard', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            _StubTransactionRepository(),
          ),
        ],
        child: const TriWalletApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TriWallet'), findsOneWidget);
  });

  testWidgets('Dashboard navigates to CSV and PDF export', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            _StubTransactionRepository(),
          ),
        ],
        child: const TriWalletApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('ບໍ່ມີລາຍການໃນຊ່ວງນີ້'), findsOneWidget);
  });

  testWidgets('Quick Add formats amount input and displays the date', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            _StubTransactionRepository(),
          ),
        ],
        child: const MaterialApp(home: QuickAddScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(formatDate(DateTime.now())), findsOneWidget);

    final amountField = find.byType(TextFormField).first;
    await tester.enterText(amountField, '100000');
    await tester.pump();
    expect(_amountText(tester, amountField), '100,000');

    await tester.tap(find.text('THB'));
    await tester.pump();
    await tester.enterText(amountField, '1250.5');
    await tester.pump();
    expect(_amountText(tester, amountField), '1,250.5');
  });

  testWidgets('History displays dates as dd/MM/yyyy', (tester) async {
    final transaction = WalletTransaction()
      ..id = 1
      ..currency = Currency.LAK
      ..amount = 1000
      ..type = TransactionType.expense
      ..category = 'Food'
      ..date = DateTime(2026, 10, 21);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            _StubTransactionRepository(transactions: [transaction]),
          ),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ຈ່າຍ · 21/10/2026'), findsOneWidget);
  });

  testWidgets('Analytics ALL mode renders separate currency chart sets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final analyticsByCurrency = {
      Currency.LAK: _analyticsData(100000),
      Currency.THB: _analyticsData(4275),
      Currency.USD: CurrencyAnalytics(
        hasTransactions: false,
        expensesByCategory: [],
        monthlyTotals: _emptyMonthlyTotals(),
      ),
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            _StubTransactionRepository(
                analyticsByCurrency: analyticsByCurrency),
          ),
        ],
        child: const MaterialApp(home: AnalyticsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LAK'), findsNWidgets(2));
    expect(find.text('THB'), findsNWidgets(2));
    expect(find.text('USD'), findsNWidgets(2));
    expect(find.text('₭100,000'), findsOneWidget);
    expect(find.text('฿42.75'), findsOneWidget);
    expect(find.text('ຍັງບໍ່ມີລາຍການ'), findsOneWidget);
    expect(find.byType(PieChart), findsNWidgets(2));
    expect(find.byType(BarChart), findsNWidgets(3));
    expect(find.text('ລາຍຈ່າຍຕາມໝວດໝູ່'), findsNWidgets(3));
  });
}

CurrencyAnalytics _analyticsData(int amount) => CurrencyAnalytics(
      hasTransactions: true,
      expensesByCategory: [
        CategoryExpenseTotal(category: 'Food', amount: amount),
      ],
      monthlyTotals: [
        for (var month = 0; month < 12; month++)
          MonthlyTransactionTotals(
            month: DateTime(2026, month + 1),
            income: amount,
            expense: amount,
          ),
      ],
    );

List<MonthlyTransactionTotals> _emptyMonthlyTotals() => [
      for (var month = 0; month < 12; month++)
        MonthlyTransactionTotals(
          month: DateTime(2025, 11 + month),
          income: 0,
          expense: 0,
        ),
    ];

String _amountText(WidgetTester tester, Finder formField) {
  final textField = find.descendant(
    of: formField,
    matching: find.byType(TextField),
  );
  return tester.widget<TextField>(textField).controller!.text;
}

class _StubTransactionRepository implements TransactionRepository {
  _StubTransactionRepository({
    this.transactions = const [],
    this.analyticsByCurrency = const {},
  });

  final List<WalletTransaction> transactions;
  final Map<Currency, CurrencyAnalytics> analyticsByCurrency;

  @override
  Future<bool> deleteTransaction(int id) async => false;

  @override
  Future<TransactionSummary> getSummary(Currency currency, DateRange range) {
    return Future.value(const TransactionSummary(income: 0, expense: 0));
  }

  @override
  Future<void> saveTransaction(WalletTransaction transaction) async {}

  @override
  Stream<TransactionSummary> watchSummary(Currency currency, DateRange range) {
    return Stream.value(const TransactionSummary(income: 0, expense: 0));
  }

  @override
  Future<CurrencyAnalytics> getAnalytics(
    Currency currency, {
    DateTime? now,
  }) async =>
      analyticsByCurrency[currency] ??
      const CurrencyAnalytics(
        hasTransactions: false,
        expensesByCategory: [],
        monthlyTotals: [],
      );

  @override
  Stream<CurrencyAnalytics> watchAnalytics(
    Currency currency, {
    DateTime? now,
  }) =>
      Stream.value(
        analyticsByCurrency[currency] ??
            const CurrencyAnalytics(
              hasTransactions: false,
              expensesByCategory: [],
              monthlyTotals: [],
            ),
      );

  @override
  Stream<List<WalletTransaction>> watchTransactions({Currency? currency}) {
    final results = currency == null
        ? transactions
        : transactions.where((item) => item.currency == currency).toList();
    return Stream.value(results);
  }
}
