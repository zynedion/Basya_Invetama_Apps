import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../forms/presentation/form_routes.dart';
import '../../../core/widgets/basya_components.dart';
import '../../../core/widgets/module_page_header.dart';
import '../domain/savings_overview_data.dart';

const _savingsScrollPhysics = BouncingScrollPhysics(
  parent: AlwaysScrollableScrollPhysics(),
);

class SavingsPage extends StatefulWidget {
  const SavingsPage({
    super.key,
    this.data = SavingsOverviewData.demo,
    this.onTopUp,
    this.onWithdraw,
    this.onPayMandatory,
    this.onSeeAllTransactions,
  });

  final SavingsOverviewData data;
  final VoidCallback? onTopUp;
  final VoidCallback? onWithdraw;
  final VoidCallback? onPayMandatory;
  final VoidCallback? onSeeAllTransactions;

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  bool _balanceVisible = true;

  String _money(int value) {
    final digits = value.toString();
    final formatted = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write('.');
      }
      formatted.write(digits[index]);
    }
    return 'Rp $formatted';
  }

  String _sensitiveMoney(int value) =>
      _balanceVisible ? _money(value) : 'Rp •••••••';

  void _showPlaceholder(String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$action akan tersedia pada tahap berikutnya.')),
      );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
    child: ScrollConfiguration(
      behavior: const _SavingsScrollBehavior(),
      child: CustomScrollView(
        key: const ValueKey('savings-page-scroll'),
        physics: _savingsScrollPhysics,
        slivers: [
          SliverToBoxAdapter(
            child: _SavingsHero(
              balance: _sensitiveMoney(widget.data.voluntarySavings),
              balanceVisible: _balanceVisible,
              onToggleBalance: () =>
                  setState(() => _balanceVisible = !_balanceVisible),
              onTopUp:
                  widget.onTopUp ??
                  () => openBasyaForm(context, BasyaFormKind.topUpSavings),
              onWithdraw:
                  widget.onWithdraw ??
                  () => openBasyaForm(context, BasyaFormKind.withdraw),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 150),
            sliver: SliverList.list(
              children: [
                const Text(
                  'Simpanan keanggotaan',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Simpanan pokok dan wajib dapat ditarik setelah keanggotaan berakhir.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                _MembershipCard(
                  icon: Icons.payments_outlined,
                  label: 'Estimasi SHU ${widget.data.shuYear}',
                  amount: _sensitiveMoney(widget.data.annualShu),
                  caption:
                      'Nilai sementara. Jumlah final mengikuti tutup buku koperasi.',
                ),
                const SizedBox(height: 10),
                _MembershipCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'Simpanan Wajib',
                  amount: _sensitiveMoney(widget.data.mandatorySavings),
                  sideLabel: 'Iuran bulanan',
                  actionLabel: 'Bayar',
                  onAction:
                      widget.onPayMandatory ??
                      () => openBasyaForm(
                        context,
                        BasyaFormKind.mandatorySavings,
                      ),
                ),
                const SizedBox(height: 10),
                _MembershipCard(
                  icon: Icons.verified_outlined,
                  label: 'Simpanan Pokok',
                  amount: _sensitiveMoney(widget.data.principalSavings),
                  sideLabel: 'Dibayar saat\ndaftar',
                ),
                const SizedBox(height: 42),
                _SectionHeader(
                  title: 'Transaksi simpanan',
                  action: 'Lihat semua',
                  onAction:
                      widget.onSeeAllTransactions ??
                      () => _showPlaceholder('Riwayat transaksi'),
                ),
                const SizedBox(height: 8),
                for (
                  var index = 0;
                  index < widget.data.transactions.length;
                  index++
                ) ...[
                  _TransactionRow(
                    transaction: widget.data.transactions[index],
                    money: _money,
                  ),
                  if (index != widget.data.transactions.length - 1)
                    const Divider(height: 1, indent: 52),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SavingsScrollBehavior extends MaterialScrollBehavior {
  const _SavingsScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => _savingsScrollPhysics;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class _SavingsHero extends StatelessWidget {
  const _SavingsHero({
    required this.balance,
    required this.balanceVisible,
    required this.onToggleBalance,
    required this.onTopUp,
    required this.onWithdraw,
  });

  final String balance;
  final bool balanceVisible;
  final VoidCallback onToggleBalance;
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const ModulePageHeader(
        title: 'Simpanan',
        subtitle: 'Kelola simpanan dan hasil usaha Anda',
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.heroRadius),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.heroGradientColors,
                stops: AppTheme.heroGradientStops,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -74,
                  bottom: -92,
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x665FE6AD), Color(0x005FE6AD)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Simpanan Sukarela',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Saldo yang dapat ditarik',
                        style: TextStyle(
                          color: Color(0xFFD9F3EE),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              balance,
                              key: const ValueKey('savings-voluntary-balance'),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onToggleBalance,
                            tooltip: balanceVisible
                                ? 'Sembunyikan saldo'
                                : 'Tampilkan saldo',
                            icon: Icon(
                              balanceVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: BasyaActionButton(
                              icon: Icons.add_rounded,
                              label: 'Top Up Sukarela',
                              onPressed: onTopUp,
                              style: BasyaActionStyle.secondary,
                              expand: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BasyaActionButton(
                              icon: Icons.arrow_downward_rounded,
                              label: 'Withdraw',
                              onPressed: onWithdraw,
                              style: BasyaActionStyle.secondary,
                              expand: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.icon,
    required this.label,
    required this.amount,
    this.caption,
    this.sideLabel,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final String amount;
  final String? caption;
  final String? sideLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 78),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      border: Border.all(color: AppTheme.cardBorder),
      boxShadow: const [
        BoxShadow(
          color: AppTheme.softShadow,
          offset: Offset(0, 8),
          blurRadius: 22,
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF8F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.teal, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (sideLabel != null)
          SizedBox(
            width: 86,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sideLabel!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 5),
                  BasyaActionButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    icon: Icons.add_rounded,
                    style: BasyaActionStyle.secondary,
                    compact: true,
                  ),
                ],
              ],
            ),
          ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      TextButton(
        onPressed: onAction,
        child: Text(
          action,
          style: const TextStyle(
            color: AppTheme.teal,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.money});

  final SavingsTransaction transaction;
  final String Function(int) money;

  Color get _amountColor => switch (transaction.direction) {
    SavingsTransactionDirection.incoming => AppTheme.positive,
    SavingsTransactionDirection.outgoing => AppTheme.negative,
    SavingsTransactionDirection.neutral => AppTheme.ink,
  };

  String get _prefix => switch (transaction.direction) {
    SavingsTransactionDirection.incoming => '+',
    SavingsTransactionDirection.outgoing => '-',
    SavingsTransactionDirection.neutral => '',
  };

  IconData get _icon => switch (transaction.direction) {
    SavingsTransactionDirection.incoming => Icons.south_west_rounded,
    SavingsTransactionDirection.outgoing => Icons.north_east_rounded,
    SavingsTransactionDirection.neutral => Icons.verified_outlined,
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF8F5),
            borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          ),
          child: Icon(_icon, color: AppTheme.teal, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${transaction.date} · ${transaction.status}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$_prefix${money(transaction.amount)}',
          style: TextStyle(
            color: _amountColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
