import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ModulePageHeader extends StatelessWidget {
  const ModulePageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onHelp,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onHelp,
            tooltip: 'Tentang $title',
            icon: const Icon(
              Icons.help_outline_rounded,
              color: AppTheme.teal,
              size: 21,
            ),
          ),
        ],
      ),
    ),
  );
}
