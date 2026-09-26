import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_profile.dart';
import '../../multiguna/domain/multiguna_overview_data.dart';
import '../domain/form_preview.dart';
import 'basya_form_page.dart';

export '../domain/form_preview.dart' show BasyaFormKind;

Future<void> openBasyaForm(
  BuildContext context,
  BasyaFormKind kind, {
  AuthProfile? profile,
  MultigunaLoan? loan,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    settings: RouteSettings(name: '/forms/${kind.name}'),
    builder: (_) => BasyaFormPage(kind: kind, profile: profile, loan: loan),
  ),
);

Future<void> openTopUpDestination(
  BuildContext context, {
  required bool investor,
}) async {
  if (!investor) {
    await openBasyaForm(context, BasyaFormKind.topUpSavings);
    return;
  }
  final destination = await showModalBottomSheet<BasyaFormKind>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tujuan Top Up',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Pilih saldo yang ingin Anda tambahkan.',
              style: TextStyle(fontSize: 14, color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            for (final option in [
              BasyaFormKind.topUpSavings,
              BasyaFormKind.topUpBuyPower,
            ])
              Card.outlined(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    option == BasyaFormKind.topUpSavings
                        ? Icons.savings_outlined
                        : Icons.account_balance_wallet_outlined,
                    color: AppTheme.teal,
                  ),
                  title: Text(
                    option == BasyaFormKind.topUpSavings
                        ? 'Simpanan Sukarela'
                        : 'Buy Power',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    option == BasyaFormKind.topUpSavings
                        ? 'Saldo simpanan yang dapat ditarik'
                        : 'Dana untuk pembelian investasi',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, option),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (destination != null && context.mounted) {
    await openBasyaForm(context, destination);
  }
}
