import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/loan_detail.dart';

String loanDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

Future<void> showLoanDetail(
  BuildContext context, {
  required Future<LoanDetail> Function() load,
  required String reference,
  required String Function(int) money,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _LoanSheet(load: load, reference: reference, money: money),
);

class _LoanSheet extends StatefulWidget {
  const _LoanSheet({
    required this.load,
    required this.reference,
    required this.money,
  });
  final Future<LoanDetail> Function() load;
  final String reference;
  final String Function(int) money;
  @override
  State<_LoanSheet> createState() => _LoanSheetState();
}

class _LoanSheetState extends State<_LoanSheet> {
  late Future<LoanDetail> _future = widget.load();
  String _filter = 'Semua';
  final _scroll = ScrollController();
  bool _more = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_check);
  }

  void _check() {
    if (!mounted || !_scroll.hasClients) return;
    final more = _scroll.position.extentAfter > 24;
    if (more != _more) setState(() => _more = more);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(String? source) async {
    final uri = Uri.tryParse(source ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dokumen belum dapat dibuka. Silakan coba lagi.'),
        ),
      );
    }
  }

  Widget _line(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .88,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail pinjaman',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.reference,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<LoanDetail>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Detail pinjaman belum dapat dimuat.'),
                      TextButton(
                        onPressed: () =>
                            setState(() => _future = widget.load()),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                );
              }
              final data = snapshot.data!;
              final items = data.installments
                  .where(
                    (i) =>
                        _filter == 'Semua' ||
                        (_filter == 'Lunas' ? i.paid : i.status == 'billing'),
                  )
                  .toList();
              WidgetsBinding.instance.addPostFrameCallback((_) => _check());
              return Stack(
                children: [
                  NotificationListener<ScrollMetricsNotification>(
                    onNotification: (_) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _check(),
                      );
                      return false;
                    },
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 72),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.neutralSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                data.object['asset_type']?.toString() ??
                                    'Pembiayaan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                (data.contract['status'] as Map?)?['label']
                                        ?.toString() ??
                                    '',
                                style: const TextStyle(color: AppTheme.teal),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sisa kewajiban',
                                style: TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                widget.money(data.amount('outstanding')),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Cicilan reguler ${widget.money(data.amount('installment'))} / bulan',
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${data.summary['paid']} dari ${data.summary['total']} cicilan lunas',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Jadwal cicilan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final label in [
                                'Semua',
                                'Belum dibayar',
                                'Lunas',
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(label),
                                    selected: _filter == label,
                                    onSelected: (_) =>
                                        setState(() => _filter = label),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Tidak ada cicilan pada filter ini.'),
                          ),
                        for (final item in items)
                          ExpansionTile(
                            key: PageStorageKey('loan-installment-${item.id}'),
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              'Cicilan ke-${item.number}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Jatuh tempo ${loanDate(item.dueDate)}'),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: item.paid
                                        ? AppTheme.positive
                                        : item.overdue
                                        ? AppTheme.negative
                                        : const Color(0xFF976A13),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  item.paid
                                      ? 'Dibayar ${widget.money(item.amount)}'
                                      : 'Cicilan reguler ${widget.money(data.amount('installment'))}',
                                ),
                              ],
                            ),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _line('Nomor transaksi', item.reference),
                                    if (item.paymentDate != null)
                                      _line(
                                        'Tanggal pembayaran',
                                        loanDate(item.paymentDate!),
                                      ),
                                    if (item.paid) ...[
                                      _line(
                                        'Pokok',
                                        widget.money(item.principal),
                                      ),
                                      _line(
                                        'Margin',
                                        widget.money(item.margin),
                                      ),
                                      _line(
                                        'Penyesuaian',
                                        widget.money(item.adjustment),
                                      ),
                                      if (item.method != null)
                                        _line(
                                          'Metode pembayaran',
                                          item.method!,
                                        ),
                                    ],
                                    if (item.receipt != null)
                                      TextButton.icon(
                                        onPressed: () => _open(item.receipt),
                                        icon: const Icon(Icons.receipt_long),
                                        label: const Text(
                                          'Lihat bukti pembayaran',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text(
                            'Informasi pembiayaan',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          children: [
                            for (final pair in {
                              'Plafon': 'plafon',
                              'Uang muka': 'down_payment',
                              'Margin': 'margin',
                              'Biaya administrasi': 'administration_fee',
                              'Total pembiayaan': 'total_financing',
                              'Total pembayaran': 'total_payment',
                              'Sisa pokok': 'remaining_principal',
                              'Sisa margin': 'remaining_margin',
                            }.entries)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _line(
                                  pair.key,
                                  widget.money(data.amount(pair.value)),
                                ),
                              ),
                            _line('Tenor', '${data.financing['tenor']} bulan'),
                            _line(
                              'Periode kontrak',
                              '${data.contract['start_date']} – ${data.contract['end_date']}',
                            ),
                            _line(
                              'Penyedia',
                              data.object['supplier_name']?.toString() ?? '—',
                            ),
                          ],
                        ),
                        if (data.contract['document_url'] != null)
                          TextButton.icon(
                            onPressed: () =>
                                _open(data.contract['document_url'] as String),
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('Lihat dokumen akad'),
                          ),
                      ],
                    ),
                  ),
                  if (_more)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.neutralSurface.withValues(
                              alpha: .88,
                            ),
                          ),
                          onPressed: () => _scroll.animateTo(
                            (_scroll.offset + 250).clamp(
                              0,
                              _scroll.position.maxScrollExtent,
                            ),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          label: const Text('Informasi lainnya'),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
