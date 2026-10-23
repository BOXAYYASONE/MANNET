import '../models/currency.dart';

String formatMoney(int amount, Currency currency) {
  final symbol = switch (currency) {
    Currency.LAK => '₭',
    Currency.THB => '฿',
    Currency.USD => r'$',
  };
  final sign = amount < 0 ? '-' : '';
  final absoluteAmount = amount.abs();
  final digits = _groupThousands(absoluteAmount.toString());

  if (currency == Currency.LAK) {
    return '$sign$symbol$digits';
  }

  final wholeUnits = _groupThousands((absoluteAmount ~/ 100).toString());
  final minorUnits = (absoluteAmount % 100).toString().padLeft(2, '0');
  return '$sign$symbol$wholeUnits.$minorUnits';
}

String _groupThousands(String digits) {
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      grouped.write(',');
    }
    grouped.write(digits[index]);
  }
  return grouped.toString();
}
