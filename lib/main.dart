import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/wallet_transaction.dart';
import 'providers/summary_providers.dart';
import 'repositories/transaction_repository.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [WalletTransactionSchema],
    directory: directory.path,
  );
  final repository = TransactionRepository(isar);

  runApp(
    ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(
          repository,
        ),
      ],
      child: const TriWalletApp(),
    ),
  );
}

class TriWalletApp extends StatelessWidget {
  const TriWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MNCK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F9D7A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9F8),
        cardColor: Colors.white,
        fontFamily: 'Phetsarath OT',
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Color(0x14000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
