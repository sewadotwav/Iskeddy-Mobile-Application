import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_text_styles.dart';
import 'pill_button.dart';

/// Generic empty-state widget — icon, title, optional subtitle, optional
/// button. Used on Screen 1 (no pinned / no classes today), Screen 2
/// (no schedules), and Screen 3 (no courses).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.icon,
    this.iconBackground = const Color(0xFFF2F2F2),
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0.0, -0.30), 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBackground),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: appFont(fontSize: 15, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: appFont(fontSize: 13, color: const Color(0xFF8A8A8A)),
              textAlign: TextAlign.center,
            ),
          ],
          if (buttonLabel != null) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: PillButton(
                label: buttonLabel!,
                background: accentColor,
                textColor: Colors.white,
                onTap: onButtonTap ?? () {},
              ),
            ),
          ],
        ],
      ),
    );
  }
}