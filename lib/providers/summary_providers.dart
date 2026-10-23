import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/currency.dart';
import '../models/summary_period.dart';
import '../models/wallet_transaction.dart';
import '../repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => throw UnimplementedError(
    'transactionRepositoryProvider must be overridden with an Isar repository.',
  ),
);

final transactionSaveProvider = StateNotifierProvider.autoDispose<
    TransactionSaveNotifier, AsyncValue<void>>((ref) {
  return TransactionSaveNotifier(ref.watch(transactionRepositoryProvider));
});

class TransactionSaveNotifier extends StateNotifier<AsyncValue<void>> {
  TransactionSaveNotifier(this._repository) : super(const AsyncData(null));

  final TransactionRepository _repository;

  Future<void> save(WalletTransaction transaction) async {
    state = const AsyncLoading();
    try {
      await _repository.saveTransaction(transaction);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final transactionHistoryProvider =
    StreamProvider.family<List<WalletTransaction>, Currency?>((ref, currency) {
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactions(currency: currency);
});

final transactionDeleteProvider = StateNotifierProvider.autoDispose<
    TransactionDeleteNotifier, AsyncValue<void>>((ref) {
  return TransactionDeleteNotifier(ref.watch(transactionRepositoryProvider));
});

class TransactionDeleteNotifier extends StateNotifier<AsyncValue<void>> {
  TransactionDeleteNotifier(this._repository) : super(const AsyncData(null));

  final TransactionRepository _repository;

  Future<void> delete(int id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteTransaction(id);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final summaryProvider = StreamProvider.family<TransactionSummary,
    ({Currency currency, SummaryPeriod period})>((ref, selection) {
  final repository = ref.watch(transactionRepositoryProvider);
  final range = DateRange.forPeriod(selection.period);
  return repository.watchSummary(selection.currency, range);
});

final analyticsProvider =
    StreamProvider.family<CurrencyAnalytics, Currency>((ref, currency) {
  return ref.watch(transactionRepositoryProvider).watchAnalytics(currency);
});
