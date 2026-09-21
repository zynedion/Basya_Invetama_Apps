import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum BasyaActionStyle { primary, emphasis, secondary, tonal, danger }

class BasyaActionButton extends StatefulWidget {
  const BasyaActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = BasyaActionStyle.primary,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BasyaActionStyle style;
  final bool expand;
  final bool compact;

  @override
  State<BasyaActionButton> createState() => _BasyaActionButtonState();
}

class _BasyaActionButtonState extends State<BasyaActionButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (widget.style) {
      BasyaActionStyle.primary => Colors.white,
      BasyaActionStyle.emphasis => Colors.white,
      BasyaActionStyle.secondary => AppTheme.teal,
      BasyaActionStyle.tonal => AppTheme.teal,
      BasyaActionStyle.danger => AppTheme.negative,
    };
    final background = switch (widget.style) {
      BasyaActionStyle.primary => Colors.transparent,
      BasyaActionStyle.emphasis => AppTheme.teal,
      BasyaActionStyle.secondary => Colors.white,
      BasyaActionStyle.tonal => const Color(0xFFEDF8F5),
      BasyaActionStyle.danger => const Color(0xFFFFF1EE),
    };
    final border = switch (widget.style) {
      BasyaActionStyle.primary => Colors.transparent,
      BasyaActionStyle.emphasis => AppTheme.teal,
      BasyaActionStyle.secondary => const Color(0xFFBCEBDD),
      BasyaActionStyle.tonal => const Color(0xFFD7E9E5),
      BasyaActionStyle.danger => const Color(0xFFFFB7AA),
    };
    final enabled = widget.onPressed != null;
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? .98 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : .48,
            duration: const Duration(milliseconds: 160),
            child: Container(
              constraints: BoxConstraints(
                minHeight: widget.compact ? 44 : 48,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 12 : 16,
                vertical: widget.compact ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: background,
                gradient: widget.style == BasyaActionStyle.primary
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF004E50),
                          Color(0xFF006A66),
                          Color(0xFF008579),
                        ],
                        stops: [0, .5, 1],
                      )
                    : null,
                borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                border: Border.all(color: border),
                boxShadow:
                    widget.style == BasyaActionStyle.primary ||
                        widget.style == BasyaActionStyle.emphasis
                    ? const [
                        BoxShadow(
                          color: Color(0x1F004E50),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: widget.expand
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: foreground,
                      size: widget.compact ? 17 : 19,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: ExcludeSemantics(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: widget.compact ? 11 : 12,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
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
    );
    return widget.expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

class BasyaSegmentedControl<T> extends StatelessWidget {
  const BasyaSegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 48),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F6F4),
      borderRadius: BorderRadius.circular(AppTheme.actionRadius),
      border: Border.all(color: const Color(0xFFDDE8E5)),
    ),
    child: Row(
      children: [
        for (final value in values)
          Expanded(
            child: Material(
              color: value == selected ? AppTheme.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              child: InkWell(
                onTap: () => onChanged(value),
                borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    labelBuilder(value),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: value == selected ? Colors.white : AppTheme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

enum BasyaStatusTone { neutral, success, warning, danger }

class BasyaStatusBadge extends StatelessWidget {
  const BasyaStatusBadge({
    super.key,
    required this.text,
    this.icon,
    this.tone = BasyaStatusTone.neutral,
  });

  final String text;
  final IconData? icon;
  final BasyaStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      BasyaStatusTone.neutral => AppTheme.neutralSurface,
      BasyaStatusTone.success => AppTheme.successSurface,
      BasyaStatusTone.warning => AppTheme.warningSurface,
      BasyaStatusTone.danger => AppTheme.dangerSurface,
    };
    final foreground = switch (tone) {
      BasyaStatusTone.neutral => AppTheme.teal,
      BasyaStatusTone.success => const Color(0xFF087B56),
      BasyaStatusTone.warning => AppTheme.warning,
      BasyaStatusTone.danger => const Color(0xFFD83B27),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground, size: 12),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BasyaFilterChip extends StatelessWidget {
  const BasyaFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppTheme.teal : Colors.white,
    borderRadius: BorderRadius.circular(99),
    child: InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppTheme.teal : AppTheme.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
