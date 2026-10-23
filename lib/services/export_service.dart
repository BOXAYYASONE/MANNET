import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/currency.dart';
import '../models/transaction_type.dart';
import '../models/wallet_transaction.dart';
import '../utils/date_format.dart';
import '../utils/money_format.dart';

class CurrencyReport {
  const CurrencyReport({
    required this.currency,
    required this.openingBalance,
    required this.rows,
    required this.totalIncome,
    required this.totalExpense,
  });

  final Currency currency;
  final int openingBalance;
  final List<PdfTransactionRow> rows;
  final int totalIncome;
  final int totalExpense;

  int get closingBalance => openingBalance + totalIncome - totalExpense;
}

class PdfTransactionRow {
  const PdfTransactionRow({
    required this.transaction,
    required this.runningBalance,
  });

  final WalletTransaction transaction;
  final int runningBalance;
}

List<CurrencyReport> buildCurrencyReports(
  Iterable<WalletTransaction> transactions, {
  required DateTime from,
  required DateTime to,
}) {
  final start = DateTime(from.year, from.month, from.day);
  final endExclusive = DateTime(to.year, to.month, to.day + 1);
  final allTransactions = transactions.toList(growable: false);

  return Currency.values.map((currency) {
    final openingBalance = allTransactions
        .where(
          (transaction) =>
              transaction.currency == currency &&
              transaction.date.isBefore(start),
        )
        .fold<int>(
          0,
          (balance, transaction) => balance + _signedAmount(transaction),
        );
    final periodTransactions = allTransactions
        .where(
          (transaction) =>
              transaction.currency == currency &&
              !transaction.date.isBefore(start) &&
              transaction.date.isBefore(endExclusive),
        )
        .toList()
      ..sort((left, right) {
        final dateComparison = left.date.compareTo(right.date);
        return dateComparison != 0
            ? dateComparison
            : left.id.compareTo(right.id);
      });

    var runningBalance = openingBalance;
    var totalIncome = 0;
    var totalExpense = 0;
    final rows = <PdfTransactionRow>[];
    for (final transaction in periodTransactions) {
      final amount = transaction.amount;
      if (transaction.type == TransactionType.income) {
        totalIncome += amount;
      } else {
        totalExpense += amount;
      }
      runningBalance += _signedAmount(transaction);
      rows.add(
        PdfTransactionRow(
          transaction: transaction,
          runningBalance: runningBalance,
        ),
      );
    }

    return CurrencyReport(
      currency: currency,
      openingBalance: openingBalance,
      rows: List.unmodifiable(rows),
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }).toList(growable: false);
}

int _signedAmount(WalletTransaction transaction) =>
    transaction.type == TransactionType.income
        ? transaction.amount
        : -transaction.amount;

bool isTransactionInDateRange(
  WalletTransaction transaction, {
  required DateTime from,
  required DateTime to,
}) {
  final date = DateTime(
    transaction.date.year,
    transaction.date.month,
    transaction.date.day,
  );
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  return !date.isBefore(start) && !date.isAfter(end);
}

class ExportService {
  ExportService({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  static const _fontAsset = 'assets/font/Phetsarath OT.ttf';
  static const reportTitle = 'ລາຍງານລາຍຮັບລາຍຈ່າຍ';

  final AssetBundle _assetBundle;

  static String formatPdfMoney(int amount, Currency currency) {
    final symbol = switch (currency) {
      Currency.LAK => '₭',
      Currency.THB => '฿',
      Currency.USD => r'$',
    };
    final suffix = switch (currency) {
      Currency.LAK => '₭',
      Currency.THB => 'THB',
      Currency.USD => r'$',
    };
    final numberPart = formatMoney(amount.abs(), currency)
        .replaceFirst(symbol, '')
        .replaceFirst('-', '')
        .trim();
    final sign = amount < 0 ? '-' : '';
    if (currency == Currency.LAK) {
      return '$sign$numberPart$suffix';
    }
    return '$sign$numberPart $suffix';
  }

  static String dateRangeLabel(DateTime from, DateTime to) =>
      'ວັນທີ ${formatDate(from)} ຫາວັນທີ ${formatDate(to)}';

  String exportCsv(
    Iterable<WalletTransaction> transactions, {
    Currency? currency,
    required DateTime from,
    required DateTime to,
  }) {
    final rows = <List<String>>[
      const ['Currency', 'Amount', 'Category', 'Type', 'Date', 'Note'],
      for (final transaction in _sortedTransactions(transactions))
        if ((currency == null || transaction.currency == currency) &&
            isTransactionInDateRange(transaction, from: from, to: to))
          [
            transaction.currency.name,
            _formatCsvAmount(transaction.amount, transaction.currency),
            transaction.category,
            transaction.type.name,
            formatDate(transaction.date),
            transaction.note ?? '',
          ],
    ];
    return const ListToCsvConverter(eol: '\r\n').convert(rows);
  }

  Future<File> saveCsv(
    Iterable<WalletTransaction> transactions, {
    Currency? currency,
    required DateTime from,
    required DateTime to,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final currencyLabel = currency?.name ?? 'ALL';
    final fileName =
        'triwallet_${currencyLabel}_${_dateFilePart(from)}_${_dateFilePart(to)}.csv';
    final csv = exportCsv(
      transactions,
      currency: currency,
      from: from,
      to: to,
    );
    return File('${directory.path}${Platform.pathSeparator}$fileName')
        .writeAsString(csv, flush: true);
  }

  Future<Uint8List> buildPdf(
    BuildContext context,
    Iterable<WalletTransaction> transactions, {
    Currency? currency,
    required DateTime from,
    required DateTime to,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final reports = buildCurrencyReports(
      currency == null
          ? transactions
          : transactions
              .where((transaction) => transaction.currency == currency),
      from: from,
      to: to,
    ).where((report) => currency == null || report.currency == currency);
    await _assetBundle.load(_fontAsset);
    final pages = buildPdfPageLayouts(
      reports,
      from: from,
      to: to,
      currencyLabel: currency?.name ?? 'ALL',
    );
    final images = <Uint8List>[];
    for (final page in pages) {
      images.add(await _captureReportPage(overlay, page));
    }
    final document = pw.Document();
    for (final image in images) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(
            pw.MemoryImage(image),
            width: PdfPageFormat.a4.width,
            height: PdfPageFormat.a4.height,
            fit: pw.BoxFit.fill,
          ),
        ),
      );
    }
    return document.save();
  }

  Future<File> savePdf(
    BuildContext context,
    Iterable<WalletTransaction> transactions, {
    Currency? currency,
    required DateTime from,
    required DateTime to,
  }) async {
    final bytes = await buildPdf(
      context,
      transactions,
      currency: currency,
      from: from,
      to: to,
    );
    final directory = await getApplicationDocumentsDirectory();
    final currencyLabel = currency?.name ?? 'ALL';
    final fileName =
        'triwallet_report_${currencyLabel}_${_dateFilePart(from)}_${_dateFilePart(to)}.pdf';
    return File('${directory.path}${Platform.pathSeparator}$fileName')
        .writeAsBytes(bytes, flush: true);
  }
}

const _pageWidth = 595.28;
const _pageHeight = 841.89;
const _pageMargin = 56.7;
const _bodyFontSize = 7.0;
const _headerFontSize = 8.0;
const _rowsPerPage = 17;

class PdfReportPage {
  const PdfReportPage({
    required this.report,
    required this.rows,
    required this.startingNumber,
    required this.showEmptyMessage,
    required this.showSummary,
    required this.from,
    required this.to,
    required this.currencyLabel,
    required this.currencies,
    required this.openingBalances,
    required this.totalIncomeByCurrency,
    required this.totalExpenseByCurrency,
    required this.closingBalances,
  });

  final CurrencyReport report;
  final List<PdfTransactionRow> rows;
  final int startingNumber;
  final bool showEmptyMessage;
  final bool showSummary;
  final DateTime from;
  final DateTime to;
  final String currencyLabel;
  final List<Currency> currencies;
  final Map<Currency, int> openingBalances;
  final Map<Currency, int> totalIncomeByCurrency;
  final Map<Currency, int> totalExpenseByCurrency;
  final Map<Currency, int> closingBalances;

  bool get hasVisibleContent =>
      showEmptyMessage || rows.isNotEmpty || showSummary;
}

List<PdfReportPage> buildPdfPageLayouts(
  Iterable<CurrencyReport> reports, {
    required DateTime from,
    required DateTime to,
    required String currencyLabel,
}) {
  final reportsByCurrency = {
    for (final report in reports) report.currency: report,
  };
  final currenciesWithData = Currency.values.where((currency) {
    final report = reportsByCurrency[currency];
    return report != null &&
        (report.rows.isNotEmpty || report.openingBalance != 0);
  }).toList(growable: false);

  final allRows = <PdfTransactionRow>[];
  for (final currency in currenciesWithData) {
    allRows.addAll(reportsByCurrency[currency]!.rows);
  }
  allRows.sort((left, right) {
    final dateComparison = left.transaction.date.compareTo(right.transaction.date);
    if (dateComparison != 0) {
      return dateComparison;
    }
    final currencyComparison =
        left.transaction.currency.index.compareTo(right.transaction.currency.index);
    if (currencyComparison != 0) {
      return currencyComparison;
    }
    return left.transaction.id.compareTo(right.transaction.id);
  });

  final pages = <PdfReportPage>[];
  if (allRows.isEmpty) {
    final placeholder = reports.isNotEmpty
        ? reports.first
        : const CurrencyReport(
            currency: Currency.LAK,
            openingBalance: 0,
            rows: [],
            totalIncome: 0,
            totalExpense: 0,
          );
    pages.add(
      PdfReportPage(
        report: placeholder,
        rows: const [],
        startingNumber: 1,
        showEmptyMessage: true,
        showSummary: true,
        from: from,
        to: to,
        currencyLabel: currencyLabel,
        currencies: currenciesWithData,
        openingBalances: {
          for (final currency in currenciesWithData)
            currency: reportsByCurrency[currency]?.openingBalance ?? 0,
        },
        totalIncomeByCurrency: {
          for (final currency in currenciesWithData)
            currency: reportsByCurrency[currency]?.totalIncome ?? 0,
        },
        totalExpenseByCurrency: {
          for (final currency in currenciesWithData)
            currency: reportsByCurrency[currency]?.totalExpense ?? 0,
        },
        closingBalances: {
          for (final currency in currenciesWithData)
            currency: reportsByCurrency[currency]?.closingBalance ?? 0,
        },
      ),
    );
    return List.unmodifiable(pages);
  }

  for (var start = 0; start < allRows.length; start += _rowsPerPage) {
    final end = (start + _rowsPerPage).clamp(0, allRows.length);
    final pageRows = allRows.sublist(start, end);
    pages.add(
      PdfReportPage(
        report: reports.first,
        rows: pageRows,
        startingNumber: start + 1,
        showEmptyMessage: false,
        showSummary: end == allRows.length,
        from: from,
        to: to,
        currencyLabel: currencyLabel,
        currencies: currenciesWithData,
        openingBalances: {
          for (final currency in currenciesWithData)
            currency: reportsByCurrency[currency]?.openingBalance ?? 0,
        },
        totalIncomeByCurrency: {
          for (final currency in currenciesWithData)
            currency: reportsByCurrency[currency]?.totalIncome ?? 0,
        },
        totalExpenseByCurrency: {
          for (final currency in currenciesWithData)
            currency: reportsByCurrency[currency]?.totalExpense ?? 0,
        },
        closingBalances: {
          for (final currency in currenciesWithData)
            currency: reportsByCurrency[currency]?.closingBalance ?? 0,
        },
      ),
    );
  }

  return List.unmodifiable(pages);
}

Future<Uint8List> _captureReportPage(
  OverlayState overlay,
  PdfReportPage page,
) async {
  final boundaryKey = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: RepaintBoundary(
            key: boundaryKey,
            child: _buildReportPageWidget(page),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(child: ColoredBox(color: Colors.white)),
        ),
      ],
    ),
  );
  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary || !renderObject.hasSize) {
      throw StateError('Could not lay out the PDF report page for capture.');
    }
    final image = await renderObject.toImage(pixelRatio: 2);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw StateError('Could not encode the PDF report page as PNG.');
      }
      return png.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
    entry.dispose();
  }
}

Widget _buildReportPageWidget(PdfReportPage page) {
  final openingBalances = page.currencies.map((currency) {
    final balance = page.openingBalances[currency] ?? 0;
    return Text(
      'ຍອດຍົກມາ: ${_formatPdfMoney(balance, currency)}',
      style: _pdfMoneyTextStyle(balance, fontSize: 9),
    );
  });

  return SizedBox(
    width: _pageWidth,
    height: _pageHeight,
    child: Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(_pageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ExportService.reportTitle,
              style: _pdfTextStyle(fontSize: 16, bold: true),
            ),
            const SizedBox(height: 3),
            Text(
              ExportService.dateRangeLabel(page.from, page.to),
              style: _pdfTextStyle(fontSize: 9),
            ),
            if (page.currencyLabel != 'ALL') ...[
              const SizedBox(height: 12),
              Text(
                'ສະກຸນເງິນ: ${page.currencyLabel}',
                style: _pdfTextStyle(fontSize: 11, bold: true),
              ),
            ],
            if (page.currencies.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...openingBalances.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: line,
                  )),
            ],
            const SizedBox(height: 6),
            _buildFlutterTable(page),
          ],
        ),
      ),
    ),
  );
}

Widget _buildFlutterTable(PdfReportPage page) {
  final rows = <TableRow>[
    TableRow(
      decoration: const BoxDecoration(color: Color(0xffd6d6d6)),
      children: const [
        'ລ/ດ',
        'ວັນທີ',
        'ໝວດໝູ່',
        'ໝາຍເຫດ',
        'ລາຍຮັບ',
        'ລາຍຈ່າຍ',
        'ຍອດເຫຼືອ',
      ].map((label) => _tableCell(label, header: true)).toList(),
    ),
  ];

  if (page.showEmptyMessage) {
    rows.add(
      TableRow(
        children: [
          _tableCell('ບໍ່ມີລາຍການໃນຊ່ວງນີ້', colspanText: true),
          _tableCell(''),
          _tableCell(''),
          _tableCell(''),
          _tableCell(''),
          _tableCell(''),
          _tableCell(''),
        ],
      ),
    );
  } else {
    for (var index = 0; index < page.rows.length; index++) {
      final row = page.rows[index];
      final transaction = row.transaction;
      final isIncome = transaction.type == TransactionType.income;
      rows.add(
        TableRow(
          children: [
            _tableCell((page.startingNumber + index).toString()),
            _tableCell(formatDate(transaction.date)),
            _tableCell(transaction.category),
            _tableCell(transaction.note ?? ''),
            _tableMoneyCell(
              isIncome ? _formatPdfMoney(transaction.amount, transaction.currency) : '',
              isIncome ? transaction.amount : 0,
            ),
            _tableMoneyCell(
              isIncome ? '' : _formatPdfMoney(transaction.amount, transaction.currency),
              isIncome ? 0 : transaction.amount,
            ),
            _tableMoneyCell(
              _formatPdfMoney(row.runningBalance, transaction.currency),
              row.runningBalance,
            ),
          ],
        ),
      );
    }
  }

  if (page.showSummary) {
    for (final currency in page.currencies) {
      final totalIncome = page.totalIncomeByCurrency[currency] ?? 0;
      final totalExpense = page.totalExpenseByCurrency[currency] ?? 0;
      final balance = page.closingBalances[currency] ?? 0;
      rows.add(
        TableRow(
          decoration: const BoxDecoration(color: Color(0xffeeeeee)),
          children: [
            _tableCell('ລວມ', bold: true),
            _tableCell(''),
            _tableCell(''),
            _tableCell(''),
            _tableMoneyCell(
              _formatPdfMoney(totalIncome, currency),
              totalIncome,
              bold: true,
            ),
            _tableMoneyCell(
              _formatPdfMoney(totalExpense, currency),
              totalExpense,
              bold: true,
            ),
            _tableMoneyCell(
              _formatPdfMoney(balance, currency),
              balance,
              bold: true,
            ),
          ],
        ),
      );
    }
  }

  return Table(
    border: TableBorder.all(color: const Color(0xff555555), width: 0.5),
    columnWidths: const {
      0: FlexColumnWidth(0.7),
      1: FlexColumnWidth(1.2),
      2: FlexColumnWidth(1.6),
      3: FlexColumnWidth(2.7),
      4: FlexColumnWidth(1.3),
      5: FlexColumnWidth(1.3),
      6: FlexColumnWidth(1.3),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: rows,
  );
}

Widget _tableCell(
  String text, {
  bool header = false,
  bool bold = false,
  bool colspanText = false,
}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: _pdfTextStyle(
          fontSize: header ? _headerFontSize : _bodyFontSize,
          bold: header || bold,
        ),
        textAlign: colspanText ? TextAlign.left : TextAlign.center,
      ),
    );

Widget _tableMoneyCell(
  String text,
  int amount, {
  bool header = false,
  bool bold = false,
}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: _pdfMoneyTextStyle(
          amount,
          fontSize: header ? _headerFontSize : _bodyFontSize,
          bold: header || bold,
        ),
      ),
    );

TextStyle _pdfTextStyle({required double fontSize, bool bold = false}) =>
    TextStyle(
      fontFamily: 'Phetsarath OT',
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: Colors.black,
    );

TextStyle _pdfMoneyTextStyle(
  int amount, {
  required double fontSize,
  bool bold = false,
}) =>
    _pdfTextStyle(fontSize: fontSize, bold: bold).copyWith(
      color: amount < 0 ? Colors.red : Colors.black,
    );

Iterable<WalletTransaction> _sortedTransactions(
  Iterable<WalletTransaction> transactions,
) {
  final sorted = transactions.toList()
    ..sort((left, right) {
      final dateComparison = left.date.compareTo(right.date);
      if (dateComparison != 0) {
        return dateComparison;
      }
      final currencyComparison =
          left.currency.index.compareTo(right.currency.index);
      return currencyComparison != 0
          ? currencyComparison
          : left.id.compareTo(right.id);
    });
  return sorted;
}

String _formatCsvAmount(int minorUnits, Currency currency) {
  if (currency == Currency.LAK) {
    return minorUnits.toString();
  }
  final sign = minorUnits < 0 ? '-' : '';
  final absoluteAmount = minorUnits.abs();
  final wholeUnits = absoluteAmount ~/ 100;
  final fractionalUnits = (absoluteAmount % 100).toString().padLeft(2, '0');
  return '$sign$wholeUnits.$fractionalUnits';
}

String _dateFilePart(DateTime date) => '${date.year.toString().padLeft(4, '0')}'
    '${date.month.toString().padLeft(2, '0')}'
    '${date.day.toString().padLeft(2, '0')}';

String _formatPdfMoney(int amount, Currency currency) {
  final symbol = switch (currency) {
    Currency.LAK => '₭',
    Currency.THB => '฿',
    Currency.USD => r'$',
  };
  final suffix = switch (currency) {
    Currency.LAK => '₭',
    Currency.THB => 'THB',
    Currency.USD => r'$',
  };
  final numberPart = formatMoney(amount.abs(), currency)
      .replaceFirst(symbol, '')
      .replaceFirst('-', '')
      .trim();
  final sign = amount < 0 ? '-' : '';
  if (currency == Currency.LAK) {
    return '$sign$numberPart$suffix';
  }
  return '$sign$numberPart $suffix';
}

int pdfPageCount(Uint8List pdfBytes) {
  final text = latin1.decode(pdfBytes, allowInvalid: true);
  return RegExp(r'/Type\s*/Page\b').allMatches(text).length;
}
