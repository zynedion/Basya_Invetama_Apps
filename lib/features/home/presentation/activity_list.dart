import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/investor_home_data.dart';

class ActivityList extends StatelessWidget {
  const ActivityList({
    super.key,
    required this.activities,
    required this.money,
  });

  final List<InvestorHomeActivity> activities;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < activities.length; index++) ...[
        _ActivityRow(activity: activities[index], money: money),
        if (index != activities.length - 1)
          const Divider(height: 1, indent: 52),
      ],
    ],
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.money});

  final InvestorHomeActivity activity;
  final String Function(int) money;

  String get _prefix => switch (activity.direction) {
    HomeActivityDirection.incoming => '+',
    HomeActivityDirection.outgoing => '-',
    HomeActivityDirection.transfer => '',
  };

  IconData get _icon => switch (activity.direction) {
    HomeActivityDirection.incoming => Icons.south_west_rounded,
    HomeActivityDirection.outgoing => Icons.north_east_rounded,
    HomeActivityDirection.transfer => Icons.swap_horiz_rounded,
  };

  Color get _amountColor => switch (activity.direction) {
    HomeActivityDirection.incoming => AppTheme.positive,
    HomeActivityDirection.outgoing => AppTheme.negative,
    HomeActivityDirection.transfer => AppTheme.ink,
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final amount = Text(
          '$_prefix${money(activity.amount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _amountColor,
          ),
        );
        final details = Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEDF7F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox.square(
                dimension: 40,
                child: Icon(_icon, size: 21, color: AppTheme.teal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (activity.referenceId != null)
                    Text(
                      activity.referenceId!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.muted,
                      ),
                    ),
                  Text(
                    [
                      activity.date,
                      if (activity.statusLabel != null) activity.statusLabel!,
                    ].join(' \u00b7 '),
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        );
        final compact =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(13) > 16;
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: amount),
                ],
              )
            : Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 8),
                  amount,
                ],
              );
      },
    ),
  );
}
