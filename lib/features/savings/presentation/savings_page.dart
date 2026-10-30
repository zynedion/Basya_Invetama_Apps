import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/data/auth_exception.dart';
import '../data/savings_api_client.dart';
import '../domain/savings_gateway.dart';
import 'savings_history_page.dart';
import 'savings_transaction_row.dart';

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
    this.session,
    this.gateway,
    this.onTopUp,
    this.onWithdraw,
    this.onPayMandatory,
    this.onSeeAllTransactions,
  });

  final SavingsOverviewData data;
  final AuthSession? session;
  final SavingsGateway? gateway;
  final VoidCallback? onTopUp;
  final VoidCallback? onWithdraw;
  final VoidCallback? onPayMandatory;
  final VoidCallback? onSeeAllTransactions;

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  bool _balanceVisible = true;
  late final SavingsApiClient _client = SavingsApiClient();
  SavingsGateway get _gateway => widget.gateway ?? _client;
  SavingsOverviewData? _remote;
  bool _loading = false;
  String? _error;
  int _request = 0;
  SavingsOverviewData get _data => widget.session == null
      ? widget.data
      : (_remote ??
            const SavingsOverviewData(
              voluntarySavings: 0,
              mandatorySavings: 0,
              principalSavings: 0,
              transactions: [],
            ));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SavingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.gateway != widget.gateway) {
      _remote = null;
      _load();
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    final session = widget.session;
    if (session == null) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _gateway.getSavings(session, limit: 5);
      if (!mounted || request != _request) return;
      setState(() {
        _remote = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = error is AuthException
            ? error.message
            : 'Simpanan belum dapat dimuat.';
      });
    }
  }

  void _openHistory() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SavingsHistoryPage(
        session: widget.session,
        gateway: _gateway,
        preview: widget.data.transactions,
        money: _balanceVisible
            ? _money
            : (_) => 'Rp \u2022\u2022\u2022\u2022\u2022\u2022',
      ),
    ),
  );

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

  String _sensitiveMoney(int value) => widget.session != null && _remote == null
      ? '\u2014'
      : _balanceVisible
      ? _money(value)
      : 'Rp •••••••';

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
    child: ScrollConfiguration(
      behavior: const _SavingsScrollBehavior(),
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          key: const ValueKey('savings-page-scroll'),
          physics: _savingsScrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: _SavingsHero(
                balance: _sensitiveMoney(_data.voluntarySavings),
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
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null) ...[
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Coba lagi'),
                    ),
                  ],
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
                    label: _data.shuYear == null
                        ? 'Estimasi SHU'
                        : 'Estimasi SHU ${_data.shuYear}',
                    amount: _data.annualShu == null
                        ? 'Belum tersedia'
                        : _sensitiveMoney(_data.annualShu!),
                    caption:
                        'Nilai sementara. Jumlah final mengikuti tutup buku koperasi.',
                  ),
                  const SizedBox(height: 10),
                  _MembershipCard(
                    icon: Icons.calendar_month_outlined,
                    label: 'Simpanan Wajib',
                    amount: _sensitiveMoney(_data.mandatorySavings),
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
                    amount: _sensitiveMoney(_data.principalSavings),
                    sideLabel: 'Dibayar saat\ndaftar',
                  ),
                  const SizedBox(height: 42),
                  _SectionHeader(
                    title: 'Transaksi simpanan',
                    action: 'Lihat semua',
                    onAction: widget.onSeeAllTransactions ?? _openHistory,
                  ),
                  const SizedBox(height: 8),
                  if (!_loading && _error == null && _data.transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Belum ada transaksi simpanan.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (
                    var index = 0;
                    index < _data.transactions.take(5).length;
                    index++
                  ) ...[
                    SavingsTransactionRow(
                      transaction: _data.transactions[index],
                      money: _sensitiveMoney,
                    ),
                    if (index != _data.transactions.take(5).length - 1)
                      const Divider(height: 1, indent: 52),
                  ],
                ],
              ),
            ),
          ],
        ),
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
