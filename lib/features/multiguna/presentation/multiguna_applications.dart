import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_session.dart';
import '../data/multiguna_application_api.dart';

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : {};
String _money(dynamic v) => v == null
    ? '—'
    : 'Rp ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
Color _color(String? status) => switch (status) {
  'pending' => const Color(0xFF996500),
  'approved' || 'active' => AppTheme.teal,
  'rejected' => AppTheme.negative,
  _ => AppTheme.muted,
};

class MultigunaApplications extends StatefulWidget {
  const MultigunaApplications({
    super.key,
    required this.session,
    this.full = false,
    this.visible = true,
  });
  final AuthSession session;
  final bool full, visible;
  @override
  State<MultigunaApplications> createState() => _MultigunaApplicationsState();
}

class _MultigunaApplicationsState extends State<MultigunaApplications> {
  final _api = MultigunaApplicationApi();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = false, _more = false;
  String? _error;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 240 &&
        _more &&
        !_loading &&
        _error == null) {
      _load(append: true);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final page = append ? _page + 1 : 1;
    try {
      List<Map<String, dynamic>> items;
      Map<String, dynamic> pagination = {};
      if (widget.full) {
        final data = await _api.applications(widget.session, page: page);
        items = (data['applications'] as List).map(_map).toList();
        pagination = _map(data['pagination']);
      } else {
        final results = await Future.wait(
          ['pending', 'approved'].map(
            (status) =>
                _api.applications(widget.session, status: status, limit: 3),
          ),
        );
        items = [
          for (final result in results)
            ...(result['applications'] as List).map(_map),
        ];
        items.sort(
          (a, b) => '${b['submitted_at']}'.compareTo('${a['submitted_at']}'),
        );
        items = items.take(3).toList();
      }
      if (!mounted) return;
      setState(() {
        final merged = append ? [..._items, ...items] : items;
        _items = {for (final item in merged) item['id']: item}.values.toList();
        _page = page;
        _more =
            widget.full &&
            items.isNotEmpty &&
            (pagination['has_next'] is bool
                ? pagination['has_next'] == true
                : items.length == 20);
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Pengajuan belum dapat dimuat.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _detail(Map<String, dynamic> item) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _ApplicationDetail(session: widget.session, id: item['id'] as int),
  );
  Widget _card(Map<String, dynamic> item) {
    final status = _map(item['status']);
    final financing = _map(item['financing']);
    final color = _color(status['code']?.toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withValues(alpha: .05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: color.withValues(alpha: .25)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () => _detail(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  status['code'] == 'rejected'
                      ? Icons.info_outline
                      : Icons.receipt_long_outlined,
                  color: color,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_map(item['object'])['asset_type'] ?? 'Pengajuan Multiguna'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${widget.visible ? _money(financing['plafon']) : 'Rp ••••••'} · ${financing['tenor'] ?? '—'} bulan',
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${status['label'] ?? 'Status belum tersedia'}',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() => Column(
    children: [
      if (_loading)
        const Padding(
          padding: EdgeInsets.all(12),
          child: LinearProgressIndicator(),
        ),
      if (_error != null) ...[
        Text(_error!),
        TextButton(
          onPressed: () => _load(append: widget.full && _page > 0),
          child: const Text('Coba lagi'),
        ),
      ],
      if (!_loading && _error == null && _items.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Belum ada pengajuan.'),
        ),
      if (widget.full && _more && !_loading && _error == null)
        TextButton(
          onPressed: () => _load(append: true),
          child: const Text('Muat berikutnya'),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    if (widget.full) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat pengajuan')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: _items.length + 1,
            itemBuilder: (_, i) =>
                i == _items.length ? _footer() : _card(_items[i]),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pengajuan aktif',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultigunaApplications(
                      session: widget.session,
                      full: true,
                      visible: widget.visible,
                    ),
                  ),
                );
                if (mounted) _load();
              },
              child: const Text('Lihat semua'),
            ),
          ],
        ),
        ..._items.map(_card),
        _footer(),
      ],
    );
  }
}

class _ApplicationDetail extends StatefulWidget {
  const _ApplicationDetail({required this.session, required this.id});
  final AuthSession session;
  final int id;
  @override
  State<_ApplicationDetail> createState() => _ApplicationDetailState();
}

class _ApplicationDetailState extends State<_ApplicationDetail> {
  final _api = MultigunaApplicationApi();
  late Future<Map<String, dynamic>> _future = _api.detail(
    widget.session,
    widget.id,
  );
  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .8,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Detail pengajuan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Detail pengajuan belum dapat dimuat.'),
                      TextButton(
                        onPressed: () => setState(
                          () =>
                              _future = _api.detail(widget.session, widget.id),
                        ),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                );
              }
              final item = snap.data!;
              final f = _map(item['financing']);
              final g = _map(item['guarantee']);
              final b = _map(item['billing']);
              final values = <String, dynamic>{
                'Nomor pengajuan': item['trx_id'],
                'Status': _map(item['status'])['label'],
                'Diajukan pada': item['submitted_at'],
                'Barang / kebutuhan': _map(item['object'])['asset_type'],
                'Harga barang / biaya kebutuhan': _money(f['price']),
                'Uang muka': _money(f['down_payment']),
                'Jumlah pembiayaan': _money(f['plafon']),
                'Jangka waktu': '${f['tenor'] ?? '—'} bulan',
                'Margin': '${f['margin_rate'] ?? '—'}%',
                'Nilai margin': _money(f['margin']),
                'Harga jual': _money(f['sale_price']),
                'Cicilan per bulan': _money(f['installment']),
                'Biaya administrasi': _money(f['administration_fee']),
                'Jaminan': g['has_guarantee'] == true ? g['type'] : 'Tidak ada',
                if (g['has_guarantee'] == true) ...{
                  'Alamat jaminan': g['address'],
                  'Status kepemilikan': g['ownership_status'],
                  'Berlaku hingga': g['valid_until'],
                  'Nomor sertifikat': g['certificate_number'],
                  'Kondisi': g['condition'],
                },
                'Mulai cicilan':
                    b['start_date'] ?? 'Ditentukan admin saat persetujuan',
                'Tanggal jatuh tempo': b['due_day'],
                'Akhir cicilan': b['end_date'],
                'Catatan': item['note'],
              };
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  for (final entry in values.entries)
                    if (entry.value != null &&
                        '${entry.value}'.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
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
                              '${entry.value}',
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
