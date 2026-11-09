import '../../home/presentation/activity_detail_sheet.dart';
import '../../home/domain/investor_home_data.dart';
import 'package:flutter/material.dart';
import '../../home/presentation/activity_list.dart';
import '../domain/savings_overview_data.dart';

class SavingsTransactionRow extends StatelessWidget {
  const SavingsTransactionRow({
    super.key,
    required this.transaction,
    required this.money,
  });

  final SavingsTransaction transaction;
  final String Function(int) money;

  InvestorHomeActivity get _activity => InvestorHomeActivity(
    title: transaction.title,
    date: transaction.date,
    amount: transaction.amount,
    referenceId: transaction.referenceId,
    statusLabel: transaction.status,
    statusCode: transaction.statusCode,
    direction: switch (transaction.direction) {
      SavingsTransactionDirection.incoming => HomeActivityDirection.incoming,
      SavingsTransactionDirection.outgoing => HomeActivityDirection.outgoing,
      SavingsTransactionDirection.neutral => HomeActivityDirection.transfer,
    },
  );

  @override
  Widget build(BuildContext context) => ActivityRow(
    activity: _activity,
    money: money,
    onTap: () => showActivityDetail(
      context,
      sheetTitle: 'Detail transaksi simpanan',
      money: money,
      extraDetails: {
        if (transaction.savingsType != null)
          'Jenis simpanan': switch (transaction.savingsType) {
            'pokok' => 'Simpanan Pokok',
            'wajib' => 'Simpanan Wajib',
            'sukarela' => 'Simpanan Sukarela',
            _ => transaction.savingsType!,
          },
      },
      activity: _activity,
    ),
  );
}
