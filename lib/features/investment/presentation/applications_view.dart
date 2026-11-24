import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/data/auth_exception.dart';
import '../data/applications_api_client.dart';
import 'opportunity_detail_sheet.dart';
import 'investment_purchase_otp_page.dart';

class ApplicationsView extends StatefulWidget {
  const ApplicationsView({
    super.key,
    required this.session,
    required this.money,
    this.gateway,
    this.preview = true,
  });
  final AuthSession session;
  final String Function(int) money;
  final ApplicationsGateway? gateway;
  final bool preview;
  @override
  State<ApplicationsView> createState() => ApplicationsViewState();
}

class ApplicationsViewState extends State<ApplicationsView> {
  final _client = ApplicationsApiClient();
  ApplicationsData? _data;
  bool _loading = false;
  String? _error;
  String? _type;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(covariant ApplicationsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.gateway != widget.gateway) {
      _data = null;
      reload();
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> reload() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await (widget.gateway ?? _client).getApplications(
        widget.session,
        type: _type,
        limit: widget.preview ? 3 : null,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = e is AuthException
            ? e.message
            : 'Pengajuan belum dapat dimuat.';
      });
    }
  }

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.preview)
        Row(
          children: [
            Expanded(
              child: Text(
                'Pengajuan aktif${_data == null ? '' : ' (${_data!.total})'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: AppTheme.loginCanvas,
                      appBar: AppBar(title: const Text('Pengajuan investasi')),
                      body: SafeArea(
                        child: ApplicationsView(
                          session: widget.session,
                          money: widget.money,
                          gateway: widget.gateway,
                          preview: false,
                        ),
                      ),
                    ),
                  ),
                );
                if (mounted) reload();
              },
              child: const Text('Lihat semua'),
            ),
          ],
        ),
      if (!widget.preview)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in <String?, String>{
                null: 'Semua',
                'pembelian': 'Pembelian',
                'penjualan': 'Penjualan',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: _type == entry.key,
                    onSelected: (_) {
                      if (_type != entry.key) {
                        setState(() {
                          _type = entry.key;
                          _data = null;
                        });
                        reload();
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) ...[
        Text(_error!),
        TextButton(onPressed: reload, child: const Text('Coba lagi')),
      ],
      if (!_loading && _error == null && _data?.items.isEmpty == true)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Belum ada pengajuan aktif.'),
        ),
      const SizedBox(height: 8),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final items = _data?.items ?? <InvestmentApplication>[];
    Widget card(int i) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ApplicationCard(
        item: items[i],
        global: _data!.global,
        money: widget.money,
        onOpenOtp:
            !_data!.global &&
                items[i].text('jenis') == 'pembelian' &&
                [
                  'verify_otp',
                  'resend_otp',
                ].contains(items[i].data['next_action'])
            ? () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvestmentPurchaseOtpPage(
                      refreshOnOpen: true,
                      session: widget.session,
                      item: items[i].data,
                    ),
                  ),
                );
                if (mounted) reload();
              }
            : null,
      ),
    );
    if (widget.preview) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_header(), for (var i = 0; i < items.length; i++) card(i)],
      );
    }
    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + 1,
        itemBuilder: (_, i) => i == 0 ? _header() : card(i - 1),
      ),
    );
  }
}

class ApplicationStatus extends StatelessWidget {
  const ApplicationStatus({super.key, required this.item});
  final InvestmentApplication item;
  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (item.status['code']) {
      'menunggu_verifikasi_otp' => (
        const Color(0xFF1765A6),
        Icons.verified_user_outlined,
      ),
      'menunggu_approval' => (const Color(0xFF936000), Icons.schedule_rounded),
      'otp_kedaluwarsa' => (const Color(0xFFB3261E), Icons.error_outline),
      _ => (AppTheme.muted, Icons.info_outline),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                item.status['label'] as String,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApplicationCard extends StatelessWidget {
  const ApplicationCard({
    super.key,
    required this.item,
    required this.global,
    required this.money,
    this.onOpenOtp,
  });
  final InvestmentApplication item;
  final bool global;
  final String Function(int) money;
  final VoidCallback? onOpenOtp;
  @override
  Widget build(BuildContext context) {
    final (color, background, border, icon) = switch (item.status['code']) {
      'menunggu_verifikasi_otp' => (
        const Color(0xFF1765A6),
        const Color(0xFFF2F8FD),
        const Color(0xFFBDD8EF),
        Icons.verified_user_outlined,
      ),
      'menunggu_approval' => (
        const Color(0xFF936000),
        const Color(0xFFFFFAEF),
        const Color(0xFFF3CF80),
        Icons.schedule_rounded,
      ),
      'otp_kedaluwarsa' => (
        const Color(0xFFB3261E),
        const Color(0xFFFFF5F4),
        const Color(0xFFF0C1BC),
        Icons.error_outline,
      ),
      _ => (
        AppTheme.muted,
        Colors.white,
        AppTheme.cardBorder,
        Icons.info_outline,
      ),
    };
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onOpenOtp ?? () => _detail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.text('nama'),
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.number('jumlah_lot')} lot \u00b7 ${money(item.number('nilai'))}',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          item.status['label'] as String,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.teal),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _detail(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppTheme.loginCanvas,
    constraints: const BoxConstraints(maxWidth: 600),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detail pengajuan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Tutup',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InvestmentDetailScroll(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.text('nama'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ApplicationStatus(item: item),
                    for (final entry in <String, String>{
                      'Nomor order': item.text('order_id'),
                      'Jenis pengajuan': item.text('jenis'),
                      if (global) 'Pemilik': item.owner,
                      'Kode produk': item.text('kode_stock'),
                      'Jumlah lot': '${item.number('jumlah_lot')} lot',
                      'Harga per lot': money(item.number('harga_per_lot')),
                      'Harga per lembar': money(
                        item.number('harga_per_lembar'),
                      ),
                      'Total nilai': money(item.number('nilai')),
                      'Diajukan pada': item.text('diajukan_pada'),
                      'OTP': item.otp['verified'] == true
                          ? 'Sudah diverifikasi'
                          : item.otp['expired'] == true
                          ? 'Kedaluwarsa'
                          : item.otp['available'] == true
                          ? 'Belum diverifikasi'
                          : 'Belum tersedia',
                      if (item.otp['expires_at'] is String)
                        'Batas waktu OTP': item.otp['expires_at'] as String,
                    }.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
