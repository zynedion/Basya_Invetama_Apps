import 'package:flutter/material.dart';
import '../../auth/domain/auth_session.dart';
import 'investment_sale_page.dart';
export 'investment_sale_page.dart' show InvestmentSalePage;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../domain/portfolio_data.dart';
import 'opportunity_detail_sheet.dart';

class PortfolioCards extends StatelessWidget {
  const PortfolioCards({
    super.key,
    required this.data,
    required this.money,
    this.session,
    this.onSaleReturned,
  });
  final PortfolioData data;
  final AuthSession? session;
  final VoidCallback? onSaleReturned;
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
                onPressed: () => showPortfolioDetail(
                  context,
                  item: item,
                  money: money,
                  session: data.isGlobal ? null : session,
                  onSaleReturned: onSaleReturned,
                ),
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
  AuthSession? session,
  VoidCallback? onSaleReturned,
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
              onPressed: item.canPreviewSale && session != null
                  ? () async {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      await navigator.push(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(
                            name: '/investment/sell',
                          ),
                          builder: (_) => InvestmentSalePage(
                            item: item,
                            money: money,
                            session: session,
                          ),
                        ),
                      );
                      onSaleReturned?.call();
                    }
                  : null,
            ),
          ),
        ],
      ),
    ),
  ),
);

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
