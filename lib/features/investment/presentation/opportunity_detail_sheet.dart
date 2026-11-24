import '../../auth/domain/auth_session.dart';
import 'investment_purchase_page.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../domain/investment_overview_data.dart';

// Display HTML as inert text; never load scripts, embedded content or links.
String opportunityDescription(String html) {
  var text = html.replaceAll(
    RegExp(r'<(script|style)\b[^>]*>[\s\S]*?</\1>', caseSensitive: false),
    '',
  );
  text = text.replaceAll(
    RegExp(r'<br\s*/?>|</p>|</div>|</li>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  text = text.replaceAllMapped(RegExp(r'&#(x[0-9a-fA-F]+|[0-9]+);'), (match) {
    final raw = match[1]!;
    final code = int.tryParse(
      raw.startsWith('x') ? raw.substring(1) : raw,
      radix: raw.startsWith('x') ? 16 : 10,
    );
    return code != null && code > 0 && code <= 0x10ffff
        ? String.fromCharCode(code)
        : '';
  });
  for (final entry in {
    '&nbsp;': ' ',
    '&quot;': '"',
    '&apos;': "'",
    '&lt;': '<',
    '&gt;': '>',
    '&amp;': '&',
  }.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  return text
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
      .trim();
}

String _endDate(String value) {
  if (value.isEmpty || value.startsWith('9999-')) return 'Tidak ditentukan';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
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

Future<void> showOpportunityDetail(
  BuildContext context, {
  required InvestmentOpportunity opportunity,
  required String Function(int) money,
  int? buyPower,
  AuthSession? session,
  VoidCallback? onPurchaseReturned,
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
  builder: (context) {
    final item = opportunity;
    final available =
        item.status == 'available' &&
        item.projectStatus == 'open' &&
        item.availableLots > 0;
    final details = <String, String>{
      'Kode produk': item.code,
      'Pengelola': item.company,
      'Kategori': item.category,
      'Harga per lembar': money(item.pricePerShare),
      'Harga per lot': money(item.pricePerLot),
      'Total nilai investasi': money(item.totalValue),
      'Total lot': '${item.totalLots} lot',
      'Lot teralokasi': '${item.allocatedLots} lot',
      'Lot pending': '${item.pendingLots} lot',
      'Sisa lot': '${item.availableLots} lot',
      'Nilai teralokasi': money(item.allocatedValue),
      'Nilai pending': money(item.pendingValue),
      'Sisa nilai': money(item.remainingValue),
      'Persentase teralokasi': '${item.allocatedPercent}%',
      'Rata-rata ROI': '${item.averageRoi}%',
      'Tanggal berakhir': _endDate(item.endDate),
      'Status proyek': item.projectStatus == 'open'
          ? 'Terbuka'
          : item.projectStatus,
      'Ketersediaan': item.status == 'available' ? 'Tersedia' : item.status,
    };
    final description = opportunityDescription(item.description);
    return SafeArea(
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
                      'Detail investasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Tutup',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InvestmentDetailScroll(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OpportunityImage(url: item.imageUrl),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (item.logoUrl.isNotEmpty) ...[
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: OpportunityImage(
                              url: item.logoUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.location,
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${money(item.pricePerLot)} / lot',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.teal,
                      ),
                    ),
                    Text(
                      '${item.availableLots} lot tersedia',
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tentang investasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description.isEmpty
                          ? 'Deskripsi belum tersedia.'
                          : description,
                      style: const TextStyle(height: 1.6, color: AppTheme.ink),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Rincian investasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final entry in details.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
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
                            const SizedBox(height: 3),
                            Text(
                              entry.value.isEmpty
                                  ? 'Belum tersedia'
                                  : entry.value,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.cardBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!available) ...[
                    const Text(
                      'Produk ini belum tersedia untuk dibeli.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                  BasyaActionButton(
                    label: 'Beli',
                    style: BasyaActionStyle.emphasis,
                    labelSize: 14,
                    disabledOpacity: .75,
                    icon: Icons.shopping_bag_outlined,
                    onPressed: available && item.pricePerLot > 0
                        ? () async {
                            final navigator = Navigator.of(context);
                            navigator.pop();
                            await navigator.push(
                              MaterialPageRoute<void>(
                                settings: const RouteSettings(
                                  name: '/investment/buy',
                                ),
                                builder: (_) => InvestmentPurchasePage(
                                  opportunity: item,
                                  session: session,
                                  buyPower: buyPower,
                                  money: money,
                                ),
                              ),
                            );
                            onPurchaseReturned?.call();
                          }
                        : null,
                    expand: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);

class OpportunityImage extends StatelessWidget {
  const OpportunityImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });
  final String url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    Widget fallback() => Container(
      color: const Color(0xFFE9F5F1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.apartment_rounded,
        color: AppTheme.teal,
        size: 36,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: uri == null || uri.scheme != 'https' || uri.host.isEmpty
            ? fallback()
            : Image.network(
                url,
                fit: fit,
                cacheWidth: 1000,
                errorBuilder: (_, error, stack) => fallback(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback(),
              ),
      ),
    );
  }
}

class InvestmentDetailScroll extends StatefulWidget {
  const InvestmentDetailScroll({super.key, required this.child});
  final Widget child;
  @override
  State<InvestmentDetailScroll> createState() => InvestmentDetailScrollState();
}

class InvestmentDetailScrollState extends State<InvestmentDetailScroll> {
  final _controller = ScrollController();
  bool _hasMore = false;
  bool _checkScheduled = false;
  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    _scheduleCheck();
  }

  void _update() {
    if (!mounted ||
        !_controller.hasClients ||
        !_controller.position.hasContentDimensions) {
      return;
    }
    final more = _controller.position.extentAfter > 4;
    if (more != _hasMore) setState(() => _hasMore = more);
  }

  void _scheduleCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _update();
    });
  }

  void _scrollMore() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final target = (position.pixels + position.viewportDimension * .75).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(target);
    } else {
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _scheduleCheck();
          return false;
        },
        child: SingleChildScrollView(
          key: const ValueKey('opportunity-detail-scroll'),
          controller: _controller,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: widget.child,
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: IgnorePointer(
          ignoring: !_hasMore,
          child: ExcludeSemantics(
            excluding: !_hasMore,
            child: AnimatedOpacity(
              opacity: _hasMore ? 1 : 0,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  IgnorePointer(
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.loginCanvas.withValues(alpha: 0),
                            AppTheme.loginCanvas.withValues(alpha: .55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.white.withValues(alpha: .70),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: AppTheme.teal.withValues(alpha: .15),
                        ),
                      ),
                      child: InkWell(
                        key: const ValueKey('opportunity-more-info'),
                        onTap: _scrollMore,
                        customBorder: const StadiumBorder(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Informasi lainnya',
                                style: TextStyle(
                                  color: AppTheme.teal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.teal,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
