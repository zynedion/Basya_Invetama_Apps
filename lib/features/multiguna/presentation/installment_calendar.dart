import '../domain/loan_detail.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../domain/installment_schedule.dart';
import '../domain/multiguna_overview_data.dart';

const _months = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

class InstallmentCalendar extends StatefulWidget {
  const InstallmentCalendar({
    super.key,
    required this.loans,
    required this.money,
    required this.onPay,
    this.details = const {},
    this.onDetail,
  });
  final Map<int, LoanDetail> details;
  final ValueChanged<MultigunaLoan>? onDetail;
  final List<MultigunaLoan> loans;
  final String Function(int) money;
  final ValueChanged<MultigunaLoan> onPay;
  @override
  State<InstallmentCalendar> createState() => _InstallmentCalendarState();
}

class _InstallmentCalendarState extends State<InstallmentCalendar> {
  late DateTime _focus;
  DateTime? _selected;
  bool _monthly = false;
  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final dates =
        widget.loans
            .where((l) => l.remainingBalance > 0)
            .map((l) => l.nextDueDate)
            .toList()
          ..sort();
    final date = dates.isEmpty ? DateTime.now() : dates.first;
    _focus = DateTime(date.year, date.month, date.day);
    _selected = null;
  }

  @override
  void didUpdateWidget(covariant InstallmentCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loans != widget.loans) _reset();
  }

  void _navigate(int direction) => setState(() {
    _focus = _monthly
        ? DateTime(_focus.year, _focus.month + direction, 1)
        : DateTime(_focus.year, _focus.month, _focus.day + 7 * direction);
    _selected = null;
  });
  @override
  Widget build(BuildContext context) {
    final first = _monthly ? DateTime(_focus.year, _focus.month, 1) : _focus;
    final start = DateTime(
      first.year,
      first.month,
      first.day - first.weekday + 1,
    );
    final days = _monthly
        ? ((first.weekday - 1 + DateTime(first.year, first.month + 1, 0).day) /
                      7)
                  .ceil() *
              7
        : 7;
    final selected = _selected == null
        ? <InstallmentOccurrence>[]
        : installmentsOn(widget.loans, _selected!, details: widget.details);
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Jadwal cicilan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_month_outlined,
                    color: AppTheme.teal,
                    size: 22,
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_months[_focus.month - 1]} ${_focus.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: _monthly
                        ? 'Bulan sebelumnya'
                        : 'Minggu sebelumnya',
                    onPressed: () => _navigate(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: _monthly
                        ? 'Bulan berikutnya'
                        : 'Minggu berikutnya',
                    onPressed: () => _navigate(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final name in ['S', 'S', 'R', 'K', 'J', 'S', 'M'])
                    Expanded(
                      child: Center(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              for (var row = 0; row < days ~/ 7; row++)
                Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final day = DateTime(
                              start.year,
                              start.month,
                              start.day + row * 7 + col,
                            );
                            if (_monthly && day.month != _focus.month) {
                              return const SizedBox(height: 48);
                            }
                            final events = installmentsOn(
                              widget.loans,
                              day,
                              details: widget.details,
                            );
                            final active = _selected == day;
                            final current = DateUtils.isSameDay(today, day);
                            final overdue = events.any((e) => e.overdue);
                            final paid =
                                events.isNotEmpty &&
                                events.every((e) => e.paid);
                            final label =
                                '${day.day} ${_months[day.month - 1]} ${day.year}';
                            return Semantics(
                              button: true,
                              selected: active,
                              label:
                                  '$label, ${events.isEmpty
                                      ? "Tidak ada jadwal"
                                      : overdue
                                      ? "Cicilan menunggak"
                                      : "Ada jadwal cicilan"}',
                              excludeSemantics: true,
                              child: InkWell(
                                key: ValueKey(
                                  'installment-day-${day.year}-${day.month}-${day.day}',
                                ),
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(
                                  () => _selected = events.isEmpty ? null : day,
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                  ),
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppTheme.teal
                                        : current
                                        ? AppTheme.neutralSurface
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    border: current
                                        ? Border.all(color: AppTheme.teal)
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: active
                                              ? Colors.white
                                              : overdue
                                              ? AppTheme.negative
                                              : AppTheme.ink,
                                          fontWeight: active
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: events.isEmpty
                                              ? Colors.transparent
                                              : overdue
                                              ? AppTheme.negative
                                              : paid
                                              ? AppTheme.positive
                                              : const Color(0xFFE6AF37),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 6),
              const Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '\u25cf Jatuh tempo / perkiraan',
                    style: TextStyle(fontSize: 10, color: Color(0xFF976A13)),
                  ),
                  Text(
                    '\u25cf Menunggak',
                    style: TextStyle(fontSize: 10, color: AppTheme.negative),
                  ),
                  Text(
                    '\u25cf Lunas',
                    style: TextStyle(fontSize: 10, color: AppTheme.positive),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() {
                  _monthly = !_monthly;
                  if (_selected != null) _focus = _selected!;
                }),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _monthly ? 'Tampilkan mingguan' : 'Lihat sebulan',
                      ),
                    ),
                    Icon(_monthly ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            '${_selected!.day} ${_months[_selected!.month - 1]} ${_selected!.year} · ${selected.length} cicilan',
            key: const ValueKey('selected-installment-heading'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          for (final event in selected)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.neutralSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      event.loan.contractNumber,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.money(event.amount),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cicilan ke-${event.number} · ${event.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                    if (event.estimated)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Tanggal dan nominal dapat berubah.',
                          style: TextStyle(fontSize: 11, color: AppTheme.muted),
                        ),
                      ),
                    if (event.item?.paymentDate != null)
                      Text(
                        'Dibayar ${event.item!.paymentDate!.day}/${event.item!.paymentDate!.month}/${event.item!.paymentDate!.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.muted,
                        ),
                      ),
                    if (event.item != null && !event.paid)
                      const Text(
                        'Nominal cicilan reguler',
                        style: TextStyle(fontSize: 11, color: AppTheme.muted),
                      ),
                    if (event.item != null && widget.onDetail != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => widget.onDetail!(event.loan),
                          child: const Text('Lihat detail pinjaman'),
                        ),
                      ),
                    if (!event.estimated && event.item == null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: BasyaActionButton(
                            label: 'Bayar',
                            compact: true,
                            style: BasyaActionStyle.emphasis,
                            onPressed: () => widget.onPay(event.loan),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
