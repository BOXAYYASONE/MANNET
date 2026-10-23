import 'package:isar/isar.dart';

import 'currency.dart';
import 'transaction_type.dart';

part 'wallet_transaction.g.dart';

@collection
class WalletTransaction {
  Id id = Isar.autoIncrement;

  @Index()
  @enumerated
  late Currency currency;

  late int amount;

  @enumerated
  late TransactionType type;

  late String category;

  @Index()
  late DateTime date;

  String? note;
}
