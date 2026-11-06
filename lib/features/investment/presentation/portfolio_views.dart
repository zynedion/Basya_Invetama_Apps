import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../domain/portfolio_data.dart';
import 'opportunity_detail_sheet.dart';

class PortfolioCards extends StatelessWidget {
  const PortfolioCards({super.key, required this.data, required this.money});
  final PortfolioData data;
  final String Function(int) money;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        data.isGlobal ? 'Portofolio seluruh investor' : 'Portofolio Anda',
        style: const TextStyle(color: AppTheme.muted),
      ),
      Text(
        '${data.items.length} kepemilikan',
        style: const TextStyle(color: AppTheme.muted, fontSize: 12),
      ),
      const SizedBox(height: 12),
      if (data.items.isEmpty) const Text('Belum ada portofolio investasi.'),
      for (final item in data.items)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.cardBorder),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: OpportunityImage(url: item.text('gambar')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          item.text('sub_produk'),
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                        if (data.isGlobal)
                          Text(
                            item.ownerName,
                            style: const TextStyle(
                              color: AppTheme.teal,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: BasyaStatusBadge(
                  text: item.selling
                      ? 'Penjualan diproses'
                      : (item.text('status') == 'aktif'
                            ? 'Aktif'
                            : item.text('status')),
                  tone: item.selling
                      ? BasyaStatusTone.warning
                      : BasyaStatusTone.neutral,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${item.lots} lot dimiliki',
                style: const TextStyle(color: AppTheme.muted),
              ),
              _Info(
                label: 'Nilai saat ini (termasuk profit bruto)',
                value: money(item.number('nilai_saat_ini')),
              ),
              _Info(label: 'Modal', value: money(item.number('modal'))),
              _Info(
                label: 'Profit bruto',
                value: money(item.number('profit')),
                color: item.number('profit') < 0
                    ? AppTheme.negative
                    : item.number('profit') > 0
                    ? AppTheme.positive
                    : AppTheme.ink,
              ),
              const SizedBox(height: 8),
              BasyaActionButton(
                label: 'Lihat detail portofolio',
                style: BasyaActionStyle.tonal,
                onPressed: () =>
                    showPortfolioDetail(context, item: item, money: money),
                expand: true,
              ),
            ],
          ),
        ),
    ],
  );
}

List<Widget> ownershipInfo(PortfolioItem item, String Function(int) money) => [
  if (item.ownerName.isNotEmpty) _Info(label: 'Pemilik', value: item.ownerName),
  _Info(label: 'Kode produk', value: item.text('kode')),
  _Info(label: 'Kategori', value: item.text('sub_produk')),
  _Info(label: 'Pengelola', value: item.text('startup')),
  _Info(label: 'Harga per lot', value: money(item.price)),
  _Info(label: 'Lot dimiliki', value: '${item.lots} lot'),
  _Info(label: 'Lot tersedia untuk dijual', value: '${item.availableLots} lot'),
  _Info(label: 'Modal', value: money(item.number('modal'))),
];

Future<void> showPortfolioDetail(
  BuildContext context, {
  required PortfolioItem item,
  required String Function(int) money,
}) => showModalBottomSheet<void>(
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
      height: MediaQuery.sizeOf(context).height * .82,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Detail portofolio',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                  OpportunityImage(url: item.text('gambar')),
                  const SizedBox(height: 16),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.text('lokasi'),
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                  ...ownershipInfo(item, money),
                  _Info(
                    label: 'Profit bruto',
                    value: money(item.number('profit')),
                  ),
                  _Info(
                    label: 'Pajak profit',
                    value: money(item.number('pajak_profit')),
                  ),
                  _Info(
                    label: 'Profit bersih',
                    value: money(item.number('profit_bersih')),
                  ),
                  _Info(
                    label: 'Nilai saat ini (termasuk profit bruto)',
                    value: money(item.number('nilai_saat_ini')),
                  ),
                  _Info(
                    label: 'Status kepemilikan',
                    value: item.text('status'),
                  ),
                  _Info(
                    label: 'Status proyek',
                    value: item.text('project_status'),
                  ),
                  _Info(
                    label: 'Aktivitas terakhir',
                    value: item.text('aktivitas_terakhir_pada'),
                  ),
                  if (item.selling)
                    const Text(
                      'Ada penjualan yang sedang diproses.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: BasyaActionButton(
              label: 'Jual',
              icon: Icons.sell_outlined,
              style: BasyaActionStyle.emphasis,
              labelSize: 14,
              disabledOpacity: .75,
              expand: true,
              onPressed: item.canPreviewSale
                  ? () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(
                            name: '/investment/sell',
                          ),
                          builder: (_) =>
                              InvestmentSalePage(item: item, money: money),
                        ),
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    ),
  ),
);

class InvestmentSalePage extends StatefulWidget {
  const InvestmentSalePage({
    super.key,
    required this.item,
    required this.money,
  });
  final PortfolioItem item;
  final String Function(int) money;
  @override
  State<InvestmentSalePage> createState() => _InvestmentSalePageState();
}

class _InvestmentSalePageState extends State<InvestmentSalePage> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  bool _reviewing = false;
  int get lots => int.tryParse(_quantity.text) ?? 0;
  int get total => lots * widget.item.price;
  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _review() async {
    if (_reviewing ||
        !widget.item.canPreviewSale ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _reviewing = true);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi penjualan'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (widget.item.ownerName.isNotEmpty)
              _Info(label: 'Pemilik', value: widget.item.ownerName),
            _Info(label: 'Jumlah lot dijual', value: '$lots lot'),
            _Info(
              label: 'Harga per lot',
              value: widget.money(widget.item.price),
            ),
            _Info(label: 'Total nilai jual', value: widget.money(total)),
            _Info(
              label: 'Sisa lot dimiliki',
              value: '${widget.item.lots - lots} lot',
            ),
            const Text(
              'Penjualan melalui aplikasi belum tersedia. Kepemilikan Anda belum berubah.',
              style: TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ubah jumlah'),
          ),
          const FilledButton(onPressed: null, child: Text('Konfirmasi jual')),
        ],
      ),
    );
    if (mounted) setState(() => _reviewing = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.loginCanvas,
    appBar: AppBar(
      title: const Text('Jual investasi'),
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
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
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
                      const Text(
                        'Informasi kepemilikan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ...ownershipInfo(widget.item, widget.money),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _quantity,
                  enabled: widget.item.canPreviewSale,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Jumlah lot dijual',
                    suffixText: 'lot',
                    helperText:
                        '${widget.item.availableLots} lot tersedia untuk dijual',
                    border: const OutlineInputBorder(),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    final quantity = int.tryParse(value ?? '') ?? 0;
                    if (quantity < 1) return 'Masukkan minimal 1 lot.';
                    if (quantity > widget.item.availableLots ||
                        quantity > widget.item.lots) {
                      return 'Jumlah melebihi lot tersedia.';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _Info(label: 'Total nilai jual', value: widget.money(total)),
                const Text(
                  'Dihitung dari jumlah lot dikalikan harga per lot.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const SizedBox(height: 24),
                BasyaActionButton(
                  label: 'Tinjau penjualan',
                  style: BasyaActionStyle.emphasis,
                  labelSize: 14,
                  expand: true,
                  onPressed: widget.item.canPreviewSale && !_reviewing
                      ? _review
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({
    required this.label,
    required this.value,
    this.color = AppTheme.ink,
  });
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? 'Belum tersedia' : value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}
