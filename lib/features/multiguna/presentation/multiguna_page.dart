import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../../core/widgets/module_page_header.dart';
import '../domain/multiguna_overview_data.dart';

String _multigunaDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

class MultigunaPage extends StatefulWidget {
  const MultigunaPage({
    super.key,
    this.data,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
  });

  final MultigunaOverviewData? data;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<MultigunaPage> createState() => _MultigunaPageState();
}

class _MultigunaPageState extends State<MultigunaPage> {
  bool _obligationVisible = true;

  String _money(int value) {
    final digits = value.toString();
    final result = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
      result.write(digits[index]);
    }
    return 'Rp $result';
  }

  String _sensitiveMoney(int value) =>
      _obligationVisible ? _money(value) : 'Rp •••••••';

  void _placeholder(String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$action akan tersedia pada tahap berikutnya.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const _MultigunaStatePage(
        icon: Icons.hourglass_top_rounded,
        title: 'Memuat Multiguna',
        message: 'Data pembiayaan Anda sedang disiapkan.',
        loading: true,
      );
    }
    if (widget.errorMessage != null) {
      return _MultigunaStatePage(
        icon: Icons.cloud_off_outlined,
        title: 'Multiguna belum dapat dimuat',
        message: widget.errorMessage!,
        actionLabel: 'Coba lagi',
        onAction: widget.onRetry,
      );
    }
    final data = widget.data ?? MultigunaOverviewData.demo;
    if (!data.accessible) {
      return const _MultigunaStatePage(
        icon: Icons.lock_outline_rounded,
        title: 'Multiguna tidak tersedia',
        message: 'Akun ini tidak memiliki akses ke data Multiguna.',
      );
    }
    if (!data.hasActiveLoan) {
      return _MultigunaStatePage(
        icon: Icons.account_balance_outlined,
        title: 'Belum ada pinjaman aktif',
        message:
            'Anda sedang tidak memiliki cicilan Multiguna. Pengajuan baru dapat dibuat selama limit tersedia.',
        actionLabel: 'Ajukan Multiguna',
        onAction: () => _placeholder('Pengajuan Multiguna'),
      );
    }
    final nearest = data.nearestLoan!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
      child: ScrollConfiguration(
        behavior: const _MultigunaScrollBehavior(),
        child: CustomScrollView(
          key: const ValueKey('multiguna-page-scroll'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _MultigunaHero(
                totalObligation: _sensitiveMoney(data.totalObligation),
                totalInstallment: _sensitiveMoney(data.totalInstallment),
                activeLoans: data.totalContracts,
                visible: _obligationVisible,
                onToggleVisibility: () =>
                    setState(() => _obligationVisible = !_obligationVisible),
                onApply: () => _placeholder('Pengajuan Multiguna'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 150),
              sliver: SliverList.list(
                children: [
                  _SectionHeader(
                    title: 'Tagihan terdekat',
                    action: 'Lihat jadwal',
                    onAction: () => _placeholder('Jadwal cicilan'),
                  ),
                  const SizedBox(height: 10),
                  _NextInstallmentCard(
                    amount: _money(nearest.nextAmount),
                    contract: nearest.contractNumber,
                    dueDate: _multigunaDate(nearest.nextDueDate),
                    overduePeriods: nearest.arrearsMonths,
                    nextInstallmentNumber: nearest.nextInstallmentNumber,
                    overdue: nearest.isOverdue,
                    onPay: () => _placeholder('Bayar cicilan'),
                  ),
                  const SizedBox(height: 30),
                  _SectionHeader(
                    title: 'Pinjaman aktif',
                    action: '${data.totalContracts} kontrak',
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < data.loans.length; index++) ...[
                    _ActiveLoanCard(
                      loan: data.loans[index],
                      money: _money,
                      onTap: () => _placeholder('Detail pinjaman'),
                    ),
                    if (index != data.loans.length - 1)
                      const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultigunaScrollBehavior extends MaterialScrollBehavior {
  const _MultigunaScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class _MultigunaStatePage extends StatelessWidget {
  const _MultigunaStatePage({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
    child: CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(
          child: ModulePageHeader(
            title: 'Multiguna',
            subtitle: 'Kelola pengajuan dan cicilan pembiayaan',
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 150),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FBFA),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const SizedBox.square(
                        dimension: 34,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    else
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppTheme.neutralSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: AppTheme.teal, size: 26),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 20),
                      BasyaActionButton(
                        label: actionLabel!,
                        onPressed: onAction,
                        icon: Icons.arrow_forward_rounded,
                        style: BasyaActionStyle.emphasis,
                        expand: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MultigunaHero extends StatelessWidget {
  const _MultigunaHero({
    required this.totalObligation,
    required this.totalInstallment,
    required this.activeLoans,
    required this.visible,
    required this.onToggleVisibility,
    required this.onApply,
  });

  final String totalObligation;
  final String totalInstallment;
  final int activeLoans;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ModulePageHeader(
          title: 'Multiguna',
          subtitle: 'Kelola pengajuan dan cicilan pembiayaan',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.heroRadius),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: AppTheme.heroGradientColors,
                  stops: AppTheme.heroGradientStops,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Total sisa kewajiban',
                    style: TextStyle(color: Color(0xFFD6F3EC), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          totalObligation,
                          key: const ValueKey('multiguna-total-obligation'),
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
                        onPressed: onToggleVisibility,
                        tooltip: visible
                            ? 'Sembunyikan kewajiban'
                            : 'Tampilkan kewajiban',
                        icon: Icon(
                          visible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Gabungan dari seluruh pinjaman aktif',
                    style: TextStyle(color: Color(0xFFD6F3EC), fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          label: 'Cicilan bulanan',
                          value: totalInstallment,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeroMetric(
                          label: 'Pinjaman aktif',
                          value: '$activeLoans kontrak',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  BasyaActionButton(
                    label: 'Ajukan Multiguna',
                    icon: Icons.add_rounded,
                    onPressed: onApply,
                    style: BasyaActionStyle.secondary,
                    expand: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 70,
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      border: Border.all(color: Colors.white.withValues(alpha: .38)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFD8F3ED), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

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
      if (action != null)
        onAction == null
            ? Text(
                action!,
                style: const TextStyle(color: AppTheme.teal, fontSize: 12),
              )
            : TextButton(
                onPressed: onAction,
                child: Text(
                  action!,
                  style: const TextStyle(color: AppTheme.teal, fontSize: 12),
                ),
              ),
    ],
  );
}

class _NextInstallmentCard extends StatelessWidget {
  const _NextInstallmentCard({
    required this.amount,
    required this.contract,
    required this.dueDate,
    required this.overduePeriods,
    required this.nextInstallmentNumber,
    required this.overdue,
    required this.onPay,
  });

  final String amount;
  final String contract;
  final String dueDate;
  final int overduePeriods;
  final int nextInstallmentNumber;
  final bool overdue;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: overdue ? const Color(0xFFFFF8F5) : const Color(0xFFF3FAF8),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      border: Border.all(
        color: overdue ? const Color(0xFFFFB7AA) : AppTheme.cardBorder,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: overdue
                    ? const Color(0xFFFFE3DC)
                    : AppTheme.neutralSurface,
                borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              ),
              child: Icon(
                overdue
                    ? Icons.warning_amber_rounded
                    : Icons.calendar_month_outlined,
                color: overdue ? const Color(0xFFD83B27) : AppTheme.teal,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overdue ? 'Cicilan menunggak' : 'Cicilan berikutnya',
                    style: TextStyle(
                      color: overdue ? const Color(0xFFD83B27) : AppTheme.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    amount,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            BasyaStatusBadge(
              text: overdue ? 'Menunggak' : 'Waktu bayar',
              icon: Icons.schedule_rounded,
              tone: overdue ? BasyaStatusTone.danger : BasyaStatusTone.warning,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$contract · Jatuh tempo $dueDate',
          style: const TextStyle(color: AppTheme.muted, fontSize: 11),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                overdue
                    ? '$overduePeriods periode belum dibayar'
                    : 'Cicilan ke-$nextInstallmentNumber siap dibayar',
                style: TextStyle(
                  color: overdue ? const Color(0xFFD83B27) : AppTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            BasyaActionButton(
              label: 'Bayar cicilan',
              icon: Icons.account_balance_wallet_outlined,
              onPressed: onPay,
              style: overdue
                  ? BasyaActionStyle.danger
                  : BasyaActionStyle.emphasis,
              compact: true,
            ),
          ],
        ),
      ],
    ),
  );
}

class _ActiveLoanCard extends StatelessWidget {
  const _ActiveLoanCard({
    required this.loan,
    required this.money,
    required this.onTap,
  });

  final MultigunaLoan loan;
  final String Function(int) money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = loan.status == MultigunaLoanStatus.overdue;
    final accent = overdue ? const Color(0xFFD83B27) : AppTheme.teal;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: overdue ? const Color(0xFFFFB7AA) : AppTheme.cardBorder,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.softShadow,
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: overdue
                          ? const Color(0xFFFFE6DF)
                          : const Color(0xFFEDF8F5),
                      borderRadius: BorderRadius.circular(
                        AppTheme.controlRadius,
                      ),
                    ),
                    child: Icon(
                      Icons.account_balance_outlined,
                      color: accent,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Multiguna ${loan.contractNumber}',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: accent),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: BasyaStatusBadge(
                  text: loan.paymentStatusLabel,
                  icon: overdue
                      ? Icons.warning_amber_rounded
                      : Icons.check_rounded,
                  tone: overdue
                      ? BasyaStatusTone.danger
                      : BasyaStatusTone.success,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sisa kewajiban',
                style: TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                money(loan.remainingBalance),
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: loan.paidProgress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE3ECE9),
                  valueColor: AlwaysStoppedAnimation(
                    overdue ? const Color(0xFFE88D7D) : AppTheme.mint,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${(loan.paidProgress * 100).round()}% terbayar',
                style: const TextStyle(color: AppTheme.muted, fontSize: 10),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cicilan ${money(loan.installmentAmount)}',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    overdue
                        ? 'Terlambat ${loan.arrearsMonths} periode'
                        : 'Berikutnya ${_multigunaDate(loan.nextDueDate)}',
                    style: TextStyle(
                      color: overdue ? accent : AppTheme.muted,
                      fontSize: 11,
                      fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
