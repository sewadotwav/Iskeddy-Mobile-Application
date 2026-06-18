import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_text_styles.dart';

/// Generic pill/badge — used for schedule/course count badges, status
/// labels ("ACTIVE SCHEDULE"), day toggles, and class-mode tags.
class AppPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color fillColor;
  final Color textColor;
  final bool selected;

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.fillColor = const Color(0xFFF2F2F2),
    this.textColor = accentColor,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? accentColor : fillColor;
    final fg = selected ? Colors.white : textColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: appFont(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}
