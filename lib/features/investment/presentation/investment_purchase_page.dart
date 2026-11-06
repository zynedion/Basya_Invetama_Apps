import '../../home/data/home_summary_api_client.dart';
import '../../home/domain/home_summary_gateway.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/data/auth_exception.dart';
import '../data/opportunities_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../domain/investment_overview_data.dart';

class InvestmentPurchasePage extends StatefulWidget {
  const InvestmentPurchasePage({
    super.key,
    required this.opportunity,
    required this.buyPower,
    required this.money,
    this.session,
    this.detailClient,
    this.summaryGateway,
  });
  final InvestmentOpportunity opportunity;
  final AuthSession? session;
  final OpportunitiesApiClient? detailClient;
  final HomeSummaryGateway? summaryGateway;
  final int? buyPower;
  final String Function(int) money;
  @override
  State<InvestmentPurchasePage> createState() => _InvestmentPurchasePageState();
}

class _InvestmentPurchasePageState extends State<InvestmentPurchasePage> {
  late final OpportunitiesApiClient _client =
      widget.detailClient ?? OpportunitiesApiClient();
  final _summaryClient = HomeSummaryApiClient();
  int? _loadedBuyPower;
  bool _balanceLoading = false;
  bool _globalBalance = false;
  String? _balanceError;
  int? get _buyPower =>
      widget.session == null ? widget.buyPower : _loadedBuyPower;
  InvestmentOpportunity? _detail;
  bool _loading = false;
  String? _error;
  InvestmentOpportunity get _item => _detail ?? widget.opportunity;
  bool get _ready =>
      !_loading &&
      !_balanceLoading &&
      _balanceError == null &&
      _error == null &&
      (widget.session == null || _detail != null);
  @override
  void initState() {
    super.initState();
    _loadDetail();
    _loadBuyPower();
  }

  Future<void> _loadBuyPower() async {
    final session = widget.session;
    if (session == null || _balanceLoading) return;
    setState(() {
      _balanceLoading = true;
      _balanceError = null;
      _loadedBuyPower = null;
    });
    try {
      final summary = await (widget.summaryGateway ?? _summaryClient)
          .getSummary(session);
      if (!mounted) return;
      setState(() {
        _loadedBuyPower = summary.buyPower;
        _globalBalance = summary.isGlobal;
        _balanceLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _balanceLoading = false;
        _balanceError = error is AuthException
            ? error.message
            : 'Buy power belum dapat dimuat.';
      });
    }
  }

  Future<void> _loadDetail() async {
    final session = widget.session;
    if (session == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _client.getOpportunity(
        session,
        widget.opportunity.id,
      );
      if (!mounted) return;
      setState(() {
        _detail = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is AuthException
            ? error.message
            : 'Detail investasi belum dapat dimuat.';
      });
    }
  }

  final _form = GlobalKey<FormState>();
  final _lots = TextEditingController();
  bool _reviewing = false;
  int get _quantity => int.tryParse(_lots.text) ?? 0;
  int get _total => _quantity * _item.pricePerLot;
  @override
  void dispose() {
    if (widget.detailClient == null) _client.close();
    _summaryClient.close();
    _lots.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final lots = int.tryParse(value ?? '');
    if (lots == null || lots < 1) return 'Masukkan minimal 1 lot.';
    if (lots > _item.availableLots) {
      return 'Maksimal ${_item.availableLots} lot tersedia.';
    }
    if (_buyPower == null) return 'Buy power belum tersedia.';
    if (lots * _item.pricePerLot > _buyPower!) {
      return 'Buy power tidak mencukupi.';
    }
    return null;
  }

  Future<void> _review() async {
    if (!_ready || _reviewing || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _reviewing = true);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi pembelian'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _item.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _ReadOnlyAmount(label: 'Jumlah pembelian', value: '$_quantity lot'),
            _ReadOnlyAmount(
              label: 'Harga per lot',
              value: widget.money(_item.pricePerLot),
            ),
            _ReadOnlyAmount(
              label: 'Total nilai dibayar',
              value: widget.money(_total),
            ),
            _ReadOnlyAmount(
              label: 'Sisa buy power',
              value: widget.money(_buyPower! - _total),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pembelian melalui aplikasi belum tersedia. Belum ada dana yang dipotong.',
              style: TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ubah jumlah'),
          ),
          const FilledButton(onPressed: null, child: Text('Konfirmasi beli')),
        ],
      ),
    );
    if (mounted) setState(() => _reviewing = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final available =
        _ready &&
        item.status == 'available' &&
        item.projectStatus == 'open' &&
        item.availableLots > 0 &&
        item.pricePerLot > 0;
    return Scaffold(
      backgroundColor: AppTheme.loginCanvas,
      appBar: AppBar(
        title: const Text('Beli investasi'),
        backgroundColor: AppTheme.loginCanvas,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.money(item.pricePerLot)} / lot',
                    style: const TextStyle(
                      color: AppTheme.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                    TextButton(
                      onPressed: _loadDetail,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                  _ProductInformation(item: item, money: widget.money),
                  const SizedBox(height: 24),
                  const Text(
                    'Rincian pembelian',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ReadOnlyAmount(
                          label: 'Buy power tersedia',
                          value: _buyPower == null
                              ? (_balanceLoading
                                    ? 'Memuat...'
                                    : 'Belum tersedia')
                              : widget.money(_buyPower!),
                        ),
                        if (_globalBalance && _buyPower != null)
                          const Text(
                            'Buy power seluruh investor (ringkasan global).',
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        if (_balanceError != null) ...[
                          Text(
                            _balanceError!,
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                          TextButton(
                            onPressed: _loadBuyPower,
                            child: const Text('Muat ulang buy power'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _lots,
                          enabled: available,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Jumlah lot',
                            suffixText: 'lot',
                            helperText: '${item.availableLots} lot tersedia',
                            border: const OutlineInputBorder(),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: _validate,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) {
                            if (available) _review();
                          },
                        ),
                        const SizedBox(height: 24),
                        _ReadOnlyAmount(
                          label: 'Total nilai dibayar',
                          value: widget.money(_total),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!available)
                    const Text('Produk ini belum tersedia untuk dibeli.'),
                  BasyaActionButton(
                    label: 'Tinjau pembelian',
                    icon: Icons.fact_check_outlined,
                    style: BasyaActionStyle.emphasis,
                    labelSize: 14,
                    disabledOpacity: .75,
                    loading: _loading || _balanceLoading,
                    onPressed: available && !_reviewing ? _review : null,
                    expand: true,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Periksa jumlah lot dan total pembayaran sebelum konfirmasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyAmount extends StatelessWidget {
  const _ReadOnlyAmount({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    ),
  );
}

class _ProductInformation extends StatelessWidget {
  const _ProductInformation({required this.item, required this.money});
  final InvestmentOpportunity item;
  final String Function(int) money;
  @override
  Widget build(BuildContext context) {
    final rows = <String, String>{
      'Produk': 'Investasi',
      'Sub-produk': item.category,
      'Pengelola': item.company,
      'Proyek': item.name,
      'Nilai proyek': money(item.totalValue),
      'Harga per lot': money(item.pricePerLot),
      'Harga per lembar': money(item.pricePerShare),
      'Total lot': '${item.totalLots} lot',
      'Lot teralokasi': '${item.allocatedLots} lot',
      'Lot pending': '${item.pendingLots} lot',
      'Lot tersedia': '${item.availableLots} lot',
      'Total nilai tersedia': money(item.remainingValue),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.cardBorder),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Informasi investasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in rows.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final label = Text(
                    row.key,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  );
                  final value = Text(
                    row.value.isEmpty ? 'Belum tersedia' : row.value,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                  if (constraints.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.2) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [label, const SizedBox(height: 4), value],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: label),
                      const SizedBox(width: 16),
                      Expanded(child: value),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
