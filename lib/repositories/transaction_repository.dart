import 'package:isar/isar.dart';

import '../models/currency.dart';
import '../models/summary_period.dart';
import '../models/transaction_type.dart';
import '../models/wallet_transaction.dart';

class TransactionSummary {
  const TransactionSummary({
    required this.income,
    required this.expense,
  });

  final int income;
  final int expense;

  int get balance => income - expense;
}

class CategoryExpenseTotal {
  const CategoryExpenseTotal({
    required this.category,
    required this.amount,
  });

  final String category;
  final int amount;
}

class MonthlyTransactionTotals {
  const MonthlyTransactionTotals({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final int income;
  final int expense;
}

class CurrencyAnalytics {
  const CurrencyAnalytics({
    required this.hasTransactions,
    required this.expensesByCategory,
    required this.monthlyTotals,
  });

  final bool hasTransactions;
  final List<CategoryExpenseTotal> expensesByCategory;
  final List<MonthlyTransactionTotals> monthlyTotals;
}

class TransactionRepository {
  const TransactionRepository(this._isar);

  final Isar _isar;

  Stream<List<WalletTransaction>> watchTransactions({
    Currency? currency,
  }) {
    if (currency == null) {
      return _isar.walletTransactions
          .where()
          .sortByDateDesc()
          .watch(fireImmediately: true);
    }

    return _isar.walletTransactions
        .filter()
        .currencyEqualTo(currency)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  Future<TransactionSummary> getSummary(
    Currency currency,
    DateRange range,
  ) async {
    final income = await _sum(currency, TransactionType.income, range);
    final expense = await _sum(currency, TransactionType.expense, range);

    return TransactionSummary(income: income, expense: expense);
  }

  Stream<TransactionSummary> watchSummary(
    Currency currency,
    DateRange range,
  ) {
    return _isar.walletTransactions
        .watchLazy(fireImmediately: true)
        .asyncMap((_) => getSummary(currency, range));
  }

  Stream<CurrencyAnalytics> watchAnalytics(
    Currency currency, {
    DateTime? now,
  }) {
    return _isar.walletTransactions
        .watchLazy(fireImmediately: true)
        .asyncMap((_) => getAnalytics(currency, now: now));
  }

  Future<CurrencyAnalytics> getAnalytics(
    Currency currency, {
    DateTime? now,
  }) async {
    final hasTransactions = await _isar.walletTransactions
            .filter()
            .currencyEqualTo(currency)
            .count() >
        0;
    final categoryTransactions = await _isar.walletTransactions
        .filter()
        .currencyEqualTo(currency)
        .and()
        .typeEqualTo(TransactionType.expense)
        .distinctByCategory()
        .findAll();
    final expensesByCategory = <CategoryExpenseTotal>[];
    for (final transaction in categoryTransactions) {
      final amount = await _sumCategoryExpenses(
        currency,
        transaction.category,
      );
      if (amount != 0) {
        expensesByCategory.add(
          CategoryExpenseTotal(
            category: transaction.category,
            amount: amount,
          ),
        );
      }
    }
    expensesByCategory
        .sort((left, right) => right.amount.compareTo(left.amount));

    final currentDate = now ?? DateTime.now();
    final firstMonth = DateTime(currentDate.year, currentDate.month - 11);
    final monthlyTotals = <MonthlyTransactionTotals>[];
    for (var offset = 0; offset < 12; offset++) {
      final month = DateTime(firstMonth.year, firstMonth.month + offset);
      final nextMonth = DateTime(month.year, month.month + 1);
      final range = DateRange(from: month, to: nextMonth);
      final income = await _sum(currency, TransactionType.income, range);
      final expense = await _sum(currency, TransactionType.expense, range);
      monthlyTotals.add(
        MonthlyTransactionTotals(
          month: month,
          income: income,
          expense: expense,
        ),
      );
    }

    return CurrencyAnalytics(
      hasTransactions: hasTransactions,
      expensesByCategory: expensesByCategory,
      monthlyTotals: monthlyTotals,
    );
  }

  Future<int> _sumCategoryExpenses(Currency currency, String category) {
    return _isar.walletTransactions
        .filter()
        .currencyEqualTo(currency)
        .and()
        .typeEqualTo(TransactionType.expense)
        .and()
        .categoryEqualTo(category)
        .amountProperty()
        .sum();
  }

  Future<int> _sum(
    Currency currency,
    TransactionType type,
    DateRange range,
  ) {
    return _isar.walletTransactions
        .filter()
        .currencyEqualTo(currency)
        .and()
        .typeEqualTo(type)
        .and()
        .dateBetween(range.from, range.to, includeUpper: false)
        .amountProperty()
        .sum();
  }

  Future<void> saveTransaction(WalletTransaction transaction) {
    return _isar.writeTxn(() async {
      await _isar.walletTransactions.put(transaction);
    });
  }

  Future<bool> deleteTransaction(Id id) {
    return _isar.writeTxn(() => _isar.walletTransactions.delete(id));
  }
}
