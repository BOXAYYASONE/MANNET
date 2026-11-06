import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triwallet/models/currency.dart';
import 'package:triwallet/models/summary_period.dart';
import 'package:triwallet/models/wallet_transaction.dart';
import 'package:triwallet/providers/summary_providers.dart';
import 'package:triwallet/repositories/transaction_repository.dart';
import 'package:triwallet/screens/profile_screen.dart';

void main() {
  testWidgets('Profile renders identity and two-step clear confirmation',
      (tester) async {
    final repository = _ProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MNCK'), findsOneWidget);
    expect(find.text('MANNETCOINKEEP'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('LAK'), findsOneWidget);
    expect(find.text('THB'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('ລຶບຂໍ້ມູນທັງໝົດ'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('ລຶບຂໍ້ມູນທັງໝົດ'));
    await tester.pumpAndSettle();
    expect(find.text('ລຶບຂໍ້ມູນທັງໝົດ?'), findsOneWidget);

    await tester.tap(find.text('ດຳເນີນການຕໍ່'));
    await tester.pumpAndSettle();
    expect(find.text('ຢືນຢັນການລຶບຂໍ້ມູນ'), findsOneWidget);

    await tester.tap(find.text('ລຶບທັງໝົດ'));
    await tester.pumpAndSettle();
    expect(repository.clearCount, 1);
  });
}

class _ProfileRepository implements TransactionRepository {
  int clearCount = 0;

  @override
  Future<void> clearTransactions() async {
    clearCount++;
  }

  @override
  Future<bool> deleteTransaction(int id) async => false;

  @override
  Future<TransactionSummary> getSummary(
    Currency currency,
    DateRange range,
  ) async =>
      const TransactionSummary(income: 0, expense: 0);

  @override
  Future<int> getOpeningBalance(Currency currency, DateTime before) async => 0;

  @override
  Future<CurrencyAnalytics> getAnalytics(
    Currency currency, {
    DateTime? now,
  }) async =>
      const CurrencyAnalytics(
        hasTransactions: false,
        expensesByCategory: [],
        monthlyTotals: [],
      );

  @override
  Future<void> saveTransaction(WalletTransaction transaction) async {}

  @override
  Stream<TransactionSummary> watchSummary(
    Currency currency,
    DateRange range,
  ) =>
      Stream.value(const TransactionSummary(income: 0, expense: 0));

  @override
  Stream<CurrencyAnalytics> watchAnalytics(
    Currency currency, {
    DateTime? now,
  }) =>
      Stream.value(
        const CurrencyAnalytics(
          hasTransactions: false,
          expensesByCategory: [],
          monthlyTotals: [],
        ),
      );

  @override
  Stream<List<WalletTransaction>> watchTransactions({Currency? currency}) =>
      Stream.value(const []);
}
