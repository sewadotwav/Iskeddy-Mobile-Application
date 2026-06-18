import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final double size;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? accentColor : const Color(0xFFF2F2F2);
    final fg = primary ? Colors.white : accentColor;

    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: fg, size: size * 0.46),
        ),
      ),
    );
  }
}
