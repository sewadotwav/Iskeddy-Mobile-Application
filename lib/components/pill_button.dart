import 'package:flutter/material.dart';
import 'app_text_styles.dart';

/// Shared pill-shaped button used inside ConfirmDialog, EmptyState, and
/// anywhere else a primary/secondary action button is needed.
class PillButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  const PillButton({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(
            child: Text(
              label,
              style: appFont(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
