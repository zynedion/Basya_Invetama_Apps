import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/savings_overview_data.dart';

class SavingsTransactionRow extends StatelessWidget {
  const SavingsTransactionRow({
    super.key,
    required this.transaction,
    required this.money,
  });

  final SavingsTransaction transaction;
  final String Function(int) money;

  Color get _amountColor => switch (transaction.direction) {
    SavingsTransactionDirection.incoming => AppTheme.positive,
    SavingsTransactionDirection.outgoing => AppTheme.negative,
    SavingsTransactionDirection.neutral => AppTheme.ink,
  };

  String get _prefix => switch (transaction.direction) {
    SavingsTransactionDirection.incoming => '+',
    SavingsTransactionDirection.outgoing => '-',
    SavingsTransactionDirection.neutral => '',
  };

  IconData get _icon => switch (transaction.direction) {
    SavingsTransactionDirection.incoming => Icons.south_west_rounded,
    SavingsTransactionDirection.outgoing => Icons.north_east_rounded,
    SavingsTransactionDirection.neutral => Icons.verified_outlined,
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF8F5),
            borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          ),
          child: Icon(_icon, color: AppTheme.teal, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${transaction.date} · ${transaction.status}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$_prefix${money(transaction.amount)}',
          style: TextStyle(
            color: _amountColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
