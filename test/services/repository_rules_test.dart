import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triwallet/models/currency.dart';
import 'package:triwallet/models/summary_period.dart';
import 'package:triwallet/models/transaction_type.dart';
import 'package:triwallet/models/wallet_transaction.dart';
import 'package:triwallet/repositories/transaction_repository.dart';

void main() {
  test('delete removes a transaction and updates income and expense summaries',
      () async {
    final repository = _InMemoryTransactionRepository([
      _transaction(
        1,
        Currency.THB,
        125050,
        TransactionType.income,
      ),
      _transaction(
        2,
        Currency.THB,
        25050,
        TransactionType.expense,
      ),
    ]);
    final range = DateRange(
      from: DateTime(2026, 1, 1),
      to: DateTime(2027, 1, 1),
    );

    final before = await repository.getSummary(Currency.THB, range);
    expect(before.income, 125050);
    expect(before.expense, 25050);

    expect(await repository.deleteTransaction(1), isTrue);
    expect(await repository.deleteTransaction(2), isTrue);
    final after = await repository.getSummary(Currency.THB, range);
    expect(after.income, 0);
    expect(after.expense, 0);
  });

  test('summary for each currency ignores transactions from other currencies',
      () async {
    final repository = _InMemoryTransactionRepository([
      _transaction(1, Currency.LAK, 100000, TransactionType.income),
      _transaction(2, Currency.THB, 5000, TransactionType.expense),
    ]);
    final range = DateRange(
      from: DateTime(2026, 1, 1),
      to: DateTime(2027, 1, 1),
    );

    final lak = await repository.getSummary(Currency.LAK, range);
    final thb = await repository.getSummary(Currency.THB, range);

    expect(lak.income, 100000);
    expect(lak.expense, 0);
    expect(lak.balance, 100000);
    expect(thb.income, 0);
    expect(thb.expense, 5000);
  });

  test('November range is half-open and 31 October is opening balance',
      () async {
    final from = DateTime(2026, 11, 1);
    final to = DateTime(2026, 11, 2);
    final october31 = DateTime(2026, 10, 31, 23, 59);
    final november1 = DateTime(2026, 11, 1);

    final range = DateRange.forPeriod(
      SummaryPeriod.currentMonth,
      now: DateTime(2026, 11, 15),
    );
    expect(range.from, from);
    expect(range.to, DateTime(2026, 12, 1));
    final reportRange = DateRange(from: from, to: to);

    expect(october31.isBefore(from), isTrue);
    expect(november1.isBefore(from), isFalse);
    expect(november1.isBefore(reportRange.to), isTrue);
    expect(DateTime(2026, 11, 2).isBefore(reportRange.to), isFalse);

    final opening = _balanceBefore(
      [october31],
      from,
      Currency.LAK,
      [100000],
    );
    expect(opening, 100000);
  });

  test(
      'WalletTransaction stores free-text category without a category relation',
      () {
    final source =
        File('lib/models/wallet_transaction.dart').readAsStringSync();
    final schema =
        File('lib/models/wallet_transaction.g.dart').readAsStringSync();

    expect(RegExp(r'late\s+String\s+category\s*;').hasMatch(source), isTrue);
    expect(source, isNot(contains('IsarLink')));
    expect(source, isNot(contains('IsarLinks')));
    expect(schema, contains('r\'category\''));
    expect(schema, contains('PropertySchema'));
  });
}

int _balanceBefore(
  List<DateTime> dates,
  DateTime rangeStart,
  Currency currency,
  List<int> amounts,
) {
  var total = 0;
  for (var index = 0; index < dates.length; index++) {
    if (dates[index].isBefore(rangeStart) && currency == Currency.LAK) {
      total += amounts[index];
    }
  }
  return total;
}

WalletTransaction _transaction(
  int id,
  Currency currency,
  int amount,
  TransactionType type,
) =>
    WalletTransaction()
      ..id = id
      ..currency = currency
      ..amount = amount
      ..type = type
      ..category = 'Test'
      ..date = DateTime(2026, 6, 1);

class _InMemoryTransactionRepository implements TransactionRepository {
  _InMemoryTransactionRepository(List<WalletTransaction> transactions)
      : _transactions = List.of(transactions);

  final List<WalletTransaction> _transactions;

  @override
  Future<void> clearTransactions() async {
    _transactions.clear();
  }

  @override
  Future<bool> deleteTransaction(int id) async {
    final index =
        _transactions.indexWhere((transaction) => transaction.id == id);
    if (index == -1) {
      return false;
    }
    _transactions.removeAt(index);
    return true;
  }

  @override
  Future<TransactionSummary> getSummary(
    Currency currency,
    DateRange range,
  ) async {
    var income = 0;
    var expense = 0;
    for (final transaction in _transactions) {
      if (transaction.currency != currency ||
          transaction.date.isBefore(range.from) ||
          !transaction.date.isBefore(range.to)) {
        continue;
      }
      if (transaction.type == TransactionType.income) {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }
    return TransactionSummary(income: income, expense: expense);
  }

  @override
  Future<int> getOpeningBalance(Currency currency, DateTime before) async {
    throw UnimplementedError();
  }

  @override
  Future<CurrencyAnalytics> getAnalytics(
    Currency currency, {
    DateTime? now,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveTransaction(WalletTransaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Stream<CurrencyAnalytics> watchAnalytics(
    Currency currency, {
    DateTime? now,
  }) =>
      const Stream.empty();

  @override
  Stream<TransactionSummary> watchSummary(
    Currency currency,
    DateRange range,
  ) =>
      const Stream.empty();

  @override
  Stream<List<WalletTransaction>> watchTransactions({Currency? currency}) =>
      Stream.value(_transactions);
}
