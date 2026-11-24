import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/domain/auth_session.dart';
import '../../forms/presentation/form_widgets.dart';
import '../domain/investment_overview_data.dart';
import '../data/investment_purchase_api.dart';
import 'investment_purchase_otp_page.dart';

String? validatePurchaseLots(String? value, Map options) {
  final lots = int.tryParse(value ?? '');
  final rules = purchaseMap(options['constraints']);
  if (lots == null || lots < purchaseInt(rules['minimum_lot']) || lots < 1) {
    return 'Masukkan minimal ${rules['minimum_lot'] ?? 1} lot.';
  }
  if (lots > purchaseInt(rules['maximum_lot'])) {
    return 'Maksimal ${rules['maximum_lot']} lot sesuai kuota dan Buy Power tersedia.';
  }
  return null;
}

class InvestmentPurchasePage extends StatefulWidget {
  const InvestmentPurchasePage({
    super.key,
    required this.opportunity,
    required this.buyPower,
    required this.money,
    this.session,
    this.api,
  });
  final InvestmentOpportunity opportunity;
  final int? buyPower;
  final String Function(int) money;
  final AuthSession? session;
  final InvestmentPurchaseApi? api;
  @override
  State<InvestmentPurchasePage> createState() => _InvestmentPurchasePageState();
}

class _InvestmentPurchasePageState extends State<InvestmentPurchasePage> {
  late final _api = widget.api ?? InvestmentPurchaseApi();
  final _form = GlobalKey<FormState>();
  final _lots = TextEditingController();
  Map<String, dynamic>? _options;
  bool _loading = true, _busy = false, _uncertain = false;
  String? _error;
  int get _stockId => int.parse('${widget.opportunity.id}');
  Map<String, dynamic> get _stock => purchaseMap(_options?['stock']);
  int get _price => purchaseInt(_stock['harga_per_lot']);
  int get _quantity => int.tryParse(_lots.text) ?? 0;
  int get _balance =>
      purchaseInt(purchaseMap(_options?['buy_power'])['available_balance']);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _lots.dispose();
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _options = null;
    });
    try {
      if (widget.session == null) throw StateError('No session');
      final data = await _api.options(widget.session!, _stockId);
      final stock = purchaseMap(data['stock']);
      if (purchaseInt(stock['id']) != _stockId ||
          data['constraints'] is! Map ||
          data['buy_power'] is! Map ||
          data['eligibility'] is! Map ||
          purchaseInt(stock['harga_per_lot']) <= 0) {
        throw StateError('Invalid options');
      }
      if (mounted) setState(() => _options = data);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is InvestmentPurchaseFailure
              ? e.message
              : 'Pilihan pembelian belum dapat dimuat. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review() async {
    if (_busy ||
        _uncertain ||
        _options == null ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final lots = _quantity;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi pembelian'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${purchaseMap(_stock['proyek'])['nama'] ?? widget.opportunity.name}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text('$lots lot x ${widget.money(_price)}'),
            const SizedBox(height: 8),
            Text(
              widget.money(lots * _price),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lanjutkan verifikasi OTP melalui WhatsApp. Pembelian akan diperiksa oleh admin.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ubah jumlah'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Konfirmasi beli'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _busy = false);
      return;
    }
    try {
      final data = await _api.create(widget.session!, _stockId, lots);
      final purchase = purchaseMap(data['purchase']);
      if (purchaseInt(purchase['id']) <= 0 ||
          purchaseInt(purchase['stock_id']) != _stockId ||
          data['otp'] is! Map ||
          data['next_action'] != 'verify_otp') {
        throw StateError('Invalid creation response');
      }
      if (!mounted) return;
      setState(() => _busy = false);
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => InvestmentPurchaseOtpPage(
            session: widget.session!,
            item: {
              ...purchase,
              'otp': data['otp'],
              'next_action': data['next_action'],
            },
          ),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final known =
          e is InvestmentPurchaseFailure &&
          [400, 401, 403, 404, 409, 422, 429].contains(e.status);
      if (known) {
        final message = e.message;
        await _load();
        if (mounted) setState(() => _error = message);
      } else {
        setState(() {
          _uncertain = true;
          _error =
              'Hasil pengajuan belum dapat dipastikan. Periksa Pengajuan aktif sebelum mencoba kembali.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligible = purchaseMap(_options?['eligibility']);
    final canBuy =
        !_loading && !_busy && !_uncertain && eligible['can_buy'] == true;
    final rows = <String, String>{
      'Produk': '${purchaseMap(_stock['produk'])['nama'] ?? '-'}',
      'Sub-produk': '${purchaseMap(_stock['sub_produk'])['nama'] ?? '-'}',
      'Pengelola': '${purchaseMap(_stock['pengelola'])['nama'] ?? '-'}',
      'Harga per lot': widget.money(_price),
      'Harga per lembar': widget.money(purchaseInt(_stock['harga_per_lembar'])),
      'Nilai proyek': widget.money(purchaseInt(_stock['total_nilai'])),
      'Total lot': '${_stock['total_lot'] ?? '-'}',
      'Lot teralokasi': '${_stock['lot_teralokasi'] ?? '-'}',
      'Lot pending': '${_stock['lot_pending'] ?? '-'}',
      'Lot tersedia': '${_stock['lot_tersedia'] ?? '-'}',
      'Total nilai tersedia': widget.money(
        purchaseInt(_stock['total_nilai_tersedia']),
      ),
    };
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Beli investasi')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (_loading) const LinearProgressIndicator(),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.negative),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_options == null && !_loading)
                      TextButton(
                        onPressed: _load,
                        child: const Text('Coba lagi'),
                      ),
                    if (_options != null) ...[
                      Text(
                        '${purchaseMap(_stock['proyek'])['nama'] ?? widget.opportunity.name}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.cardBorder),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi investasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            for (final row in rows.entries)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row.key,
                                      style: const TextStyle(
                                        color: AppTheme.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(row.value),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FormValue('Buy Power tersedia', widget.money(_balance)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _lots,
                        enabled: canBuy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Jumlah lot',
                          suffixText: 'lot',
                          helperText:
                              'Maksimal ${purchaseMap(_options!['constraints'])['maximum_lot']} lot',
                        ),
                        validator: (v) => validatePurchaseLots(v, _options!),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      FormValue(
                        'Total nilai dibayar',
                        widget.money(_quantity * _price),
                        prominent: true,
                      ),
                      const SizedBox(height: 24),
                      if (eligible['can_buy'] != true) ...[
                        Text(
                          (eligible['reasons'] as List? ??
                                  ['Pembelian belum tersedia.'])
                              .join('\n'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      BasyaActionButton(
                        label: 'Tinjau pembelian',
                        style: BasyaActionStyle.emphasis,
                        expand: true,
                        loading: _busy,
                        onPressed: canBuy ? _review : null,
                      ),
                    ],
                    if (_uncertain)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Kembali ke Investasi'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
