import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One segment of a lazy, continuous history card.
class HistoryCardSegment extends StatelessWidget {
  const HistoryCardSegment({
    super.key,
    required this.first,
    required this.last,
    required this.child,
  });
  final bool first, last;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(
        left: const BorderSide(color: AppTheme.cardBorder),
        right: const BorderSide(color: AppTheme.cardBorder),
        top: first
            ? const BorderSide(color: AppTheme.cardBorder)
            : BorderSide.none,
        bottom: last
            ? const BorderSide(color: AppTheme.cardBorder)
            : BorderSide.none,
      ),
      borderRadius: BorderRadius.vertical(
        top: first ? const Radius.circular(AppTheme.cardRadius) : Radius.zero,
        bottom: last ? const Radius.circular(AppTheme.cardRadius) : Radius.zero,
      ),
    ),
    child: child,
  );
}
