import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/domain/auth_session.dart';
import '../data/multiguna_application_api.dart';

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : {};
String _money(dynamic v) =>
    'Rp ${(v ?? 0).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

class MultigunaApplicationPage extends StatefulWidget {
  const MultigunaApplicationPage({super.key, required this.session, this.api});
  final AuthSession? session;
  final MultigunaApplicationApi? api;
  @override
  State<MultigunaApplicationPage> createState() =>
      _MultigunaApplicationPageState();
}

class _MultigunaApplicationPageState extends State<MultigunaApplicationPage> {
  late final _api = widget.api ?? MultigunaApplicationApi();
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  Map<String, dynamic>? _options, _quote;
  int? _margin;
  bool _loading = false,
      _busy = false,
      _simulating = false,
      _guarantee = false,
      _uncertain = false,
      _reviewing = false;
  int _revision = 0;
  String? _error;
  TextEditingController _controller(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);
  String _value(String key) => _fields[key]?.text.trim() ?? '';
  int _number(String key) => int.tryParse(_value(key)) ?? 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.session == null) {
      setState(() => _error = 'Silakan masuk untuk mengajukan Multiguna.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.options(widget.session!);
      if (mounted) setState(() => _options = data);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is MultigunaApplicationFailure
              ? e.message
              : 'Pilihan pengajuan belum dapat dimuat.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> get _input => {
    'price': _number('price'),
    'down_payment': _number('down_payment'),
    'margin_setup_id': _margin,
  };
  void _invalidate() {
    setState(() {
      _revision++;
      _quote = null;
    });
  }

  Future<void> _simulate() async {
    if (_simulating || _busy || widget.session == null) return;
    if (_number('price') <= 0 ||
        _value('down_payment').isEmpty ||
        _number('down_payment') > _number('price') ||
        _margin == null) {
      setState(
        () => _error =
            'Isi harga, uang muka (boleh 0), dan jangka waktu yang valid.',
      );
      return;
    }
    final revision = _revision;
    setState(() {
      _simulating = true;
      _error = null;
      _quote = null;
    });
    try {
      final result = await _api.simulate(widget.session!, _input);
      if (mounted && revision == _revision) {
        setState(() => _quote = _map(result['calculation']));
      }
    } catch (e) {
      if (mounted && revision == _revision) {
        setState(
          () => _error = e is MultigunaApplicationFailure
              ? e.message
              : 'Simulasi belum dapat dihitung. Coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  Future<void> _submit() async {
    if (_busy ||
        _reviewing ||
        _uncertain ||
        _quote?['within_limit'] != true ||
        !_form.currentState!.validate()) {
      return;
    }
    _reviewing = true;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi pengajuan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_value('asset_type')),
              const SizedBox(height: 12),
              Text('Pembiayaan ${_money(_quote!['plafon'])}'),
              Text(
                '${_quote!['tenor']} bulan · Margin ${_quote!['margin_rate']}%',
              ),
              Text('Cicilan ${_money(_quote!['installment'])}/bulan'),
              Text('Administrasi ${_money(_quote!['administration_fee'])}'),
              const SizedBox(height: 12),
              const Text(
                'Pengajuan akan diperiksa oleh admin. Jadwal cicilan ditentukan saat persetujuan.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Periksa kembali'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim pengajuan'),
          ),
        ],
      ),
    );
    _reviewing = false;
    if (!mounted || yes != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final application = await _api.submit(widget.session!, {
        'asset_type': _value('asset_type'),
        'price': '${_number('price')}',
        'down_payment': '${_number('down_payment')}',
        'margin_setup_id': '$_margin',
        'has_guarantee': '$_guarantee',
        if (_value('note').isNotEmpty) 'note': _value('note'),
        if (_guarantee)
          for (final key in [
            'type_guarantee',
            'guarantee_address',
            'ownership_status',
            'valid_until',
            'no_certificate',
            'condition_object',
          ])
            if (_value(key).isNotEmpty) key: _value(key),
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Pengajuan berhasil dikirim'),
          content: Text(
            '${_map(application['status'])['label'] ?? 'Menunggu verifikasi admin'}\n\nNomor pengajuan: ${application['trx_id']}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
      if (mounted) {
        setState(() => _busy = false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uncertain =
              e is! MultigunaApplicationFailure ||
              e.status >= 500 ||
              e.status == 0 ||
              (e.status >= 200 && e.status < 300);
          _error = _uncertain
              ? 'Status pengiriman belum dapat dipastikan. Periksa daftar pengajuan sebelum mengirim ulang.'
              : (e as MultigunaApplicationFailure).message;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _text(
    String key,
    String label, {
    bool required = false,
    bool numeric = false,
    int? maxLength,
    int lines = 1,
    bool pricing = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: _controller(key),
      enabled: !_busy,
      maxLength: maxLength,
      maxLines: lines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixText: numeric ? 'Rp ' : null,
      ),
      onChanged: pricing ? (_) => _invalidate() : null,
      validator: (v) => required && (v == null || v.trim().isEmpty)
          ? '$label wajib diisi.'
          : null,
    ),
  );
  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 16, top: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppTheme.ink,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final setups = (_options?['margin_setups'] as List? ?? [])
        .map(_map)
        .toList();
    final allowed = _map(_options?['eligibility'])['can_apply'] == true;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Ajukan Multiguna')),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_loading) const LinearProgressIndicator(),
                if (_options == null && !_loading)
                  TextButton(
                    onPressed: widget.session == null ? null : _load,
                    child: const Text('Muat pilihan pengajuan'),
                  ),
                if (_options != null) ...[
                  const Text('Limit tersedia'),
                  Text(
                    _money(_map(_options!['limit'])['available_limit']),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!allowed)
                    Text(
                      '${_map(_options!['eligibility'])['reason'] ?? 'Pengajuan belum tersedia.'}',
                    ),
                  if ((_map(_options!['profile'])['missing_fields'] as List? ??
                          [])
                      .isNotEmpty)
                    const Text(
                      'Lengkapi data profil melalui portal sebelum mengajukan.',
                    ),
                  _section('Detail pembiayaan'),
                  _text(
                    'asset_type',
                    'Barang atau kebutuhan yang dibiayai',
                    required: true,
                    maxLength: 50,
                  ),
                  _text(
                    'price',
                    'Harga barang / biaya kebutuhan',
                    required: true,
                    numeric: true,
                    pricing: true,
                  ),
                  _text(
                    'down_payment',
                    'Uang muka',
                    required: true,
                    numeric: true,
                    pricing: true,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _margin,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Jangka waktu',
                    ),
                    items: [
                      for (final s in setups)
                        DropdownMenuItem(
                          value: s['id'] as int,
                          child: Text(
                            '${s['label']} · Margin ${s['margin_rate']}%',
                          ),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (v) {
                            _margin = v;
                            _invalidate();
                          },
                  ),
                  const SizedBox(height: 20),
                  BasyaActionButton(
                    label: 'Hitung simulasi',
                    style: BasyaActionStyle.secondary,
                    loading: _simulating,
                    onPressed: allowed && !_busy && !_simulating
                        ? _simulate
                        : null,
                  ),
                  _section('Simulasi pembiayaan'),
                  if (_quote == null)
                    const Text(
                      'Lengkapi nominal dan jangka waktu, lalu hitung simulasi.',
                    ),
                  if (_quote != null) ...[
                    for (final entry in {
                      'plafon': 'Jumlah pembiayaan',
                      'margin': 'Margin Basya',
                      'sale_price': 'Harga jual Basya',
                      'installment': 'Cicilan per bulan',
                      'administration_fee': 'Biaya administrasi',
                      'remaining_limit': 'Sisa limit',
                    }.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value,
                              style: const TextStyle(color: AppTheme.muted),
                            ),
                            Text(
                              _money(_quote![entry.key]),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_quote!['within_limit'] != true)
                      const Text(
                        'Jumlah pembiayaan melebihi limit tersedia.',
                        style: TextStyle(color: AppTheme.negative),
                      ),
                  ],
                  _section('Data jaminan'),
                  BasyaSegmentedControl<bool>(
                    values: const [true, false],
                    selected: _guarantee,
                    labelBuilder: (v) => v ? 'Ada' : 'Tidak ada',
                    onChanged: (v) {
                      if (!_busy) setState(() => _guarantee = v);
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_guarantee) ...[
                    _text('type_guarantee', 'Jenis jaminan', required: true),
                    _text('guarantee_address', 'Alamat jaminan', lines: 3),
                    _text('ownership_status', 'Status kepemilikan'),
                    TextFormField(
                      controller: _controller('valid_until'),
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Berlaku hingga (opsional)',
                        suffixIcon: IconButton(
                          onPressed: _busy
                              ? null
                              : () => _controller('valid_until').clear(),
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                      onTap: _busy
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2200),
                              );
                              if (date != null && mounted) {
                                _controller('valid_until').text =
                                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                              }
                            },
                    ),
                    const SizedBox(height: 20),
                    _text('no_certificate', 'Nomor sertifikat / jaminan'),
                    _text('condition_object', 'Kondisi jaminan', lines: 3),
                  ],
                  _text(
                    'note',
                    'Catatan (opsional)',
                    maxLength: 1000,
                    lines: 3,
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.negative),
                    ),
                  ),
                BasyaActionButton(
                  label: 'Tinjau pengajuan',
                  style: BasyaActionStyle.emphasis,
                  expand: true,
                  loading: _busy,
                  onPressed:
                      allowed &&
                          !_uncertain &&
                          !_busy &&
                          !_simulating &&
                          _quote?['within_limit'] == true
                      ? _submit
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
