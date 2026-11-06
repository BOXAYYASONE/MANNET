import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/summary_providers.dart';
import 'analytics_screen.dart';
import 'export_screen.dart';
import 'history_screen.dart';

// TODO(native-speaker): Review all Lao labels and confirmation text in this file.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/mannet_logo.png',
                    width: 88,
                    height: 88,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MNCK',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'MANNETCOINKEEP',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF69736F),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _InfoCard(
            title: 'Version',
            children: [Text(_appVersion)],
          ),
          const SizedBox(height: 16),
          const _InfoCard(
            title: 'ສະກຸນເງິນທີ່ຮອງຮັບ',
            children: [
              _CurrencyRow('LAK'),
              Divider(height: 1),
              _CurrencyRow('THB'),
              Divider(height: 1),
              _CurrencyRow('USD'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShortcutTile(
                  icon: Icons.analytics_outlined,
                  label: 'ວິເຄາະ',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AnalyticsScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShortcutTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'ປະຫວັດ',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HistoryScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShortcutTile(
                  icon: Icons.upload_file_outlined,
                  label: 'ສົ່ງອອກ',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExportScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'ຂໍ້ມູນຖືກເກັບໄວ້ໃນເຄື່ອງນີ້ເທົ່ານັ້ນ '
                'ບໍ່ມີການສົ່ງຂຶ້ນເຊີບເວີ',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => _clearAllData(context, ref),
            child: const Text('ລຶບຂໍ້ມູນທັງໝົດ'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final firstConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ລຶບຂໍ້ມູນທັງໝົດ?'),
        content: const Text('ການກະທຳນີ້ຈະລຶບລາຍການທຸກລາຍການ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ຍົກເລີກ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ດຳເນີນການຕໍ່'),
          ),
        ],
      ),
    );
    if (firstConfirmed != true || !context.mounted) return;

    final secondConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ຢືນຢັນການລຶບຂໍ້ມູນ'),
        content: const Text('ທ່ານແນ່ໃຈບໍ່ວ່າຈະລຶບຂໍ້ມູນທັງໝົດ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ຍົກເລີກ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ລຶບທັງໝົດ'),
          ),
        ],
      ),
    );
    if (secondConfirmed != true || !context.mounted) return;

    await ref.read(transactionRepositoryProvider).clearTransactions();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow(this.currency);

  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(currency),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF0F9D7A)),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
