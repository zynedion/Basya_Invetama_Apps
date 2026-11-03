import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/investor_home_data.dart';

Future<void> showActivityDetail(
  BuildContext context, {
  required InvestorHomeActivity activity,
  required String Function(int) money,
  String sheetTitle = 'Detail aktivitas',
  Map<String, String> extraDetails = const {},
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
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sheetTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activity.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${switch (activity.direction) {
                HomeActivityDirection.incoming => '+',
                HomeActivityDirection.outgoing => '-',
                HomeActivityDirection.transfer => '',
              }}${money(activity.amount)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: switch (activity.direction) {
                  HomeActivityDirection.incoming => AppTheme.positive,
                  HomeActivityDirection.outgoing => AppTheme.negative,
                  HomeActivityDirection.transfer => AppTheme.ink,
                },
              ),
            ),
            const SizedBox(height: 20),
            _Detail(
              label: 'Status',
              value: activity.statusLabel ?? 'Belum tersedia',
            ),
            _Detail(
              label: 'Waktu transaksi',
              value: activity.occurredAt ?? activity.date,
            ),
            if (activity.referenceId != null)
              _Detail(label: 'Nomor referensi', value: activity.referenceId!),
            _Detail(
              label: 'Arah transaksi',
              value: switch (activity.direction) {
                HomeActivityDirection.incoming => 'Dana masuk',
                HomeActivityDirection.outgoing => 'Dana keluar',
                HomeActivityDirection.transfer => 'Transfer',
              },
            ),
            for (final entry in extraDetails.entries)
              _Detail(label: entry.key, value: entry.value),
            if (activity.stockName != null ||
                activity.lots != null ||
                activity.price != null) ...[
              const Divider(height: 28),
              const Text(
                'Rincian investasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (activity.stockName != null)
                _Detail(label: 'Nama investasi', value: activity.stockName!),
              if (activity.lots != null)
                _Detail(label: 'Jumlah lot', value: '${activity.lots} lot'),
              if (activity.price != null)
                _Detail(label: 'Harga', value: money(activity.price!)),
            ],
            if (activity.grossAmount != null || activity.taxAmount != null) ...[
              const Divider(height: 28),
              const Text(
                'Rincian nominal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (activity.grossAmount != null)
                _Detail(
                  label: 'Nominal bruto',
                  value: money(activity.grossAmount!),
                ),
              if (activity.taxAmount != null)
                _Detail(label: 'Pajak', value: money(activity.taxAmount!)),
            ],
          ],
        ),
      ),
    ),
  ),
);

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
