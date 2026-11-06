import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../forms/presentation/form_routes.dart';
import '../../../core/widgets/basya_components.dart';
import '../../../core/widgets/module_page_header.dart';
import '../domain/multiguna_overview_data.dart';
import 'installment_calendar.dart';

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
    final data = widget.data ?? MultigunaOverviewData.unavailable;
    final nearest = data.accessible ? data.nearestLoan : null;
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
                totalObligation: data.accessible
                    ? _sensitiveMoney(data.totalObligation)
                    : '\u2014',
                totalInstallment: data.accessible
                    ? _sensitiveMoney(data.totalInstallment)
                    : '\u2014',
                visible: _obligationVisible,
                onToggleVisibility: () =>
                    setState(() => _obligationVisible = !_obligationVisible),
                onApply: data.accessible
                    ? () => openBasyaForm(context, BasyaFormKind.financing)
                    : null,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 150),
              sliver: SliverList.list(
                children: [
                  InstallmentCalendar(
                    loans: data.accessible ? data.loans : const [],
                    money: _money,
                    onPay: (loan) => openBasyaForm(
                      context,
                      BasyaFormKind.installment,
                      loan: loan,
                    ),
                  ),
                  if (data.accessible)
                    for (final loan in data.loans.where(
                      (loan) => loan.arrearsAmount > 0 || loan.isOverdue,
                    )) ...[
                      const SizedBox(height: 18),
                      _OverdueNotice(
                        loan: loan,
                        money: _money,
                        onTap: () => openBasyaForm(
                          context,
                          BasyaFormKind.installment,
                          loan: loan,
                        ),
                      ),
                    ],
                  const SizedBox(height: 30),
                  _SectionHeader(
                    title: 'Pinjaman aktif',
                    action: data.accessible
                        ? '${data.totalContracts} kontrak'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  if (nearest == null)
                    _EmptyMultigunaSection(
                      message: data.accessible
                          ? 'Belum ada pinjaman aktif'
                          : 'Data pinjaman belum tersedia untuk akun ini.',
                    ),
                  if (data.accessible)
                    for (var index = 0; index < data.loans.length; index++) ...[
                      _ActiveLoanCard(loan: data.loans[index], money: _money),
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

class _EmptyMultigunaSection extends StatelessWidget {
  const _EmptyMultigunaSection({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFF7FBFA),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      border: Border.all(color: AppTheme.cardBorder),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.5),
    ),
  );
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
    required this.visible,
    required this.onToggleVisibility,
    required this.onApply,
  });
  final String totalObligation;
  final String totalInstallment;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onApply;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const ModulePageHeader(
        title: 'Multiguna',
        subtitle: 'Atur cicilan, rencanakan kebutuhan.',
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.teal,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Total sisa kewajiban',
                    style: TextStyle(color: Color(0xFFD8EFEB), fontSize: 12),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            totalObligation,
                            key: const ValueKey('multiguna-total-obligation'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
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
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Cicilan bulanan',
                        style: TextStyle(
                          color: Color(0xFFD8EFEB),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        totalInstallment,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final String? action;
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
        Text(
          action!,
          style: const TextStyle(color: AppTheme.teal, fontSize: 12),
        ),
    ],
  );
}

class _OverdueNotice extends StatelessWidget {
  const _OverdueNotice({
    required this.loan,
    required this.money,
    required this.onTap,
  });
  final MultigunaLoan loan;
  final String Function(int) money;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('overdue-${loan.contractNumber}'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5F2),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF0D1C7)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppTheme.negative, size: 23),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loan.arrearsMonths > 0
                    ? '${loan.arrearsMonths} cicilan menunggak'
                    : 'Cicilan menunggak',
                style: const TextStyle(
                  color: AppTheme.negative,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                money(loan.nextAmount),
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                loan.contractNumber,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text(
            'Lihat',
            style: TextStyle(color: AppTheme.negative),
          ),
        ),
      ],
    ),
  );
}

class _ActiveLoanCard extends StatelessWidget {
  const _ActiveLoanCard({required this.loan, required this.money});
  final MultigunaLoan loan;
  final String Function(int) money;
  String _contractDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppTheme.cardBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loan.contractNumber,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: loan.isOverdue
                    ? const Color(0xFFFFF0EB)
                    : AppTheme.neutralSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                loan.paymentStatusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: loan.isOverdue ? AppTheme.negative : AppTheme.teal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sisa kewajiban',
            style: TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  money(loan.remainingBalance),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cicilan ${money(loan.installmentAmount)} / bulan',
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: 4),
          Text(
            '${loan.paidInstallments} dari ${loan.totalInstallments} cicilan dibayar',
            style: const TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
          const SizedBox(height: 4),
          Text(
            'Periode ${_contractDate(loan.startDate)} ? ${_contractDate(loan.endDate)}',
            style: const TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
        ],
      ),
    ),
  );
}
