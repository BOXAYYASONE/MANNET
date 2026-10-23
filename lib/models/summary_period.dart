enum SummaryPeriod {
  allTime,
  currentMonth,
}

class DateRange {
  const DateRange({
    required this.from,
    required this.to,
  });

  final DateTime from;
  final DateTime to;

  factory DateRange.forPeriod(SummaryPeriod period, {DateTime? now}) {
    switch (period) {
      case SummaryPeriod.allTime:
        return DateRange(
          from: DateTime(1970),
          to: DateTime(9999),
        );
      case SummaryPeriod.currentMonth:
        final currentDate = now ?? DateTime.now();
        return DateRange(
          from: DateTime(currentDate.year, currentDate.month),
          to: DateTime(currentDate.year, currentDate.month + 1),
        );
    }
  }
}
