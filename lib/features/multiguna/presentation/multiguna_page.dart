import '../../auth/domain/auth_session.dart';
import '../data/multiguna_api_client.dart';
import '../domain/loan_detail.dart';
import 'loan_detail_sheet.dart';
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
    this.session,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
  });

  final AuthSession? session;
  final MultigunaOverviewData? data;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<MultigunaPage> createState() => _MultigunaPageState();
}

class _MultigunaPageState extends State<MultigunaPage> {
  bool _obligationVisible = true;
  final _detailClient = MultigunaApiClient();
  final _details = <int, LoanDetail>{};
  final _pending = <int, Future<LoanDetail>>{};
  bool _detailsLoading = false;
  bool _detailsIncomplete = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    widget.session?.cache?.addListener(_clearDetails);
    _loadDetails();
  }

  @override
  void didUpdateWidget(covariant MultigunaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session?.cache?.removeListener(_clearDetails);
      widget.session?.cache?.addListener(_clearDetails);
      _clearDetails();
    }
    if (oldWidget.data != widget.data || oldWidget.session != widget.session) {
      _loadDetails();
    }
  }

  void _clearDetails() {
    _generation++;
    _pending.clear();
    if (mounted) {
      setState(() {
        _details.clear();
        _detailsLoading = false;
        _detailsIncomplete = true;
      });
    }
  }

  @override
  void dispose() {
    _generation++;
    widget.session?.cache?.removeListener(_clearDetails);
    super.dispose();
  }

  Future<LoanDetail> _detail(int id, {bool refresh = false}) {
    if (!refresh && _details.containsKey(id)) return Future.value(_details[id]);
    return _pending.putIfAbsent(id, () async {
      final session = widget.session;
      if (session == null) throw StateError('No session');
      final generation = _generation;
      final key = 'multiguna:detail:$id';
      final ticket = session.cache?.begin(key);
      try {
        final detail = await _detailClient.getDetail(session, id);
        if (!mounted || generation != _generation) {
          throw StateError('Session changed');
        }
        if (ticket != null && !session.cache!.write(key, detail, ticket)) {
          throw StateError('Session changed');
        }
        setState(() => _details[id] = detail);
        return detail;
      } finally {
        if (generation == _generation) _pending.remove(id);
      }
    });
  }

  Future<void> _loadDetails() async {
    final loans = widget.data?.loans ?? [];
    if (widget.session == null || loans.isEmpty) return;
    final generation = ++_generation;
    _pending.clear();
    setState(() {
      _details.clear();
      for (final loan in loans) {
        if (loan.id == null) continue;
        final cached = widget.session?.cache?.read<LoanDetail>(
          'multiguna:detail:${loan.id}',
        );
        if (cached != null) _details[loan.id!] = cached;
      }
      _detailsLoading = true;
      _detailsIncomplete = loans.any((l) => l.id == null);
    });
    final ids = loans.map((l) => l.id).whereType<int>().toSet().toList();
    for (var i = 0; i < ids.length; i += 3) {
      if (!mounted || generation != _generation) return;
      await Future.wait(
        ids.skip(i).take(3).map((id) async {
          try {
            await _detail(id, refresh: true);
          } catch (_) {
            if (mounted && generation == _generation) {
              setState(() => _detailsIncomplete = true);
            }
          }
        }),
      );
    }
    if (mounted && generation == _generation) {
      setState(() => _detailsLoading = false);
    }
  }

  void _openDetail(MultigunaLoan loan) {
    if (loan.id == null || widget.session == null) return;
    showLoanDetail(
      context,
      reference: loan.contractNumber,
      money: _money,
      load: () => _detail(loan.id!),
    );
  }

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
                    details: _details,
                    onDetail: _openDetail,
                    onPay: (loan) => openBasyaForm(
                      context,
                      BasyaFormKind.installment,
                      loan: loan,
                    ),
                  ),
                  if (_detailsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (_detailsIncomplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          const Text(
                            'Sebagian jadwal belum tersedia. Tanggal tanpa detail masih berupa perkiraan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.muted,
                            ),
                          ),
                          TextButton(
                            onPressed: _loadDetails,
                            child: const Text('Coba lagi'),
                          ),
                        ],
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
                      _ActiveLoanCard(
                        loan: data.loans[index],
                        money: _money,
                        onDetail:
                            data.loans[index].id != null &&
                                widget.session != null
                            ? () => _openDetail(data.loans[index])
                            : null,
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
  const _ActiveLoanCard({
    required this.loan,
    required this.money,
    this.onDetail,
  });
  final VoidCallback? onDetail;
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
            'Periode ${_contractDate(loan.startDate)} - ${_contractDate(loan.endDate)}',
            style: const TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
          if (onDetail != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDetail,
                child: const Text('Lihat detail'),
              ),
            ),
        ],
      ),
    ),
  );
}
