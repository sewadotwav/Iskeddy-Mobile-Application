import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_text_styles.dart';
import 'pill_button.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.cancelLabel = 'Cancel',
    this.confirmLabel = 'Delete',
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Delete',
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierColor: accentColor.withValues(alpha: 0.25),
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.86),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: appFont(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: appFont(fontSize: 13, color: const Color(0xFF8A8A8A)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: cancelLabel,
                    background: const Color(0xFFF2F2F2),
                    textColor: accentColor,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    label: confirmLabel,
                    background: accentColor,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
