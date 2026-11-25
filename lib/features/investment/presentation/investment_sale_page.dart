import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../../auth/domain/auth_session.dart';
import '../../forms/presentation/form_widgets.dart';
import '../domain/portfolio_data.dart';
import '../data/investment_purchase_api.dart';
import 'investment_purchase_otp_page.dart';

String? validateSaleLots(String? value, Map options) {
  final lots = int.tryParse(value ?? '');
  final rules = purchaseMap(options['constraints']);
  if (lots == null || lots < purchaseInt(rules['minimum_lot']) || lots < 1) {
    return 'Masukkan minimal ${rules['minimum_lot'] ?? 1} lot.';
  }
  if (lots > purchaseInt(rules['maximum_lot'])) {
    return 'Maksimal ${rules['maximum_lot']} lot sesuai lot yang tersedia untuk dijual.';
  }
  return null;
}

class InvestmentSalePage extends StatefulWidget {
  const InvestmentSalePage({
    super.key,
    required this.item,
    required this.money,
    this.session,
    this.api,
  });
  final PortfolioItem item;
  final String Function(int) money;
  final AuthSession? session;
  final InvestmentPurchaseApi? api;
  @override
  State<InvestmentSalePage> createState() => _InvestmentSalePageState();
}

class _InvestmentSalePageState extends State<InvestmentSalePage> {
  late final _api = widget.api ?? InvestmentPurchaseApi.sale();
  final _form = GlobalKey<FormState>();
  final _lots = TextEditingController();
  Map<String, dynamic>? _options;
  bool _loading = true, _busy = false, _uncertain = false;
  String? _error;
  int get _stockId => widget.item.number('stock_id');
  Map<String, dynamic> get _stock => purchaseMap(_options?['stock']);
  Map<String, dynamic> get _position => purchaseMap(_options?['position']);
  int get _price => purchaseInt(_position['harga_per_lot']);
  int get _quantity => int.tryParse(_lots.text) ?? 0;
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
          data['position'] is! Map ||
          data['eligibility'] is! Map ||
          purchaseInt(purchaseMap(data['position'])['harga_per_lot']) <= 0) {
        throw StateError('Invalid options');
      }
      if (mounted) setState(() => _options = data);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is InvestmentPurchaseFailure
              ? e.message
              : 'Pilihan penjualan belum dapat dimuat. Silakan coba lagi.',
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
        title: const Text('Konfirmasi penjualan'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${purchaseMap(_stock['proyek'])['nama'] ?? widget.item.name}',
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
              'Lanjutkan verifikasi OTP melalui WhatsApp. Penjualan akan diperiksa oleh admin.',
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
            child: const Text('Konfirmasi jual'),
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
      final purchase = purchaseMap(data['sale']);
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
            isSale: true,
            session: widget.session!,
            item: {
              ...purchase,
              'otp': data['otp'],
              'stock_name': purchaseMap(_stock['proyek'])['nama'],
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
        !_loading && !_busy && !_uncertain && eligible['can_sell'] == true;
    final rows = <String, String>{
      'Harga per lot': widget.money(_price),
      'Harga per lembar': widget.money(
        purchaseInt(_position['harga_per_lembar']),
      ),
      'Lot dimiliki': '${_position['owned_lot']} lot',
      'Lot dalam pengajuan jual': '${_position['pending_sell_lot']} lot',
      'Lot tersedia untuk dijual': '${_position['available_lot']} lot',
      'Nilai kepemilikan': widget.money(
        purchaseInt(_position['current_value']),
      ),
      'Nilai tersedia untuk dijual': widget.money(
        purchaseInt(_position['available_value']),
      ),
    };
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Jual investasi')),
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
                        '${purchaseMap(_stock['proyek'])['nama'] ?? widget.item.name}',
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
                              'Informasi kepemilikan',
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
                      TextFormField(
                        controller: _lots,
                        enabled: canBuy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Jumlah lot dijual',
                          suffixText: 'lot',
                          helperText:
                              'Maksimal ${purchaseMap(_options!['constraints'])['maximum_lot']} lot',
                        ),
                        validator: (v) => validateSaleLots(v, _options!),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      FormValue(
                        'Total nilai jual',
                        widget.money(_quantity * _price),
                        prominent: true,
                      ),
                      const SizedBox(height: 24),
                      if (eligible['can_sell'] != true) ...[
                        Text(
                          (eligible['reasons'] as List? ??
                                  ['Penjualan belum tersedia.'])
                              .join('\n'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      BasyaActionButton(
                        label: 'Tinjau penjualan',
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
