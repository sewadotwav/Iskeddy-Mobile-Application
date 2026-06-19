import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import 'app_text_styles.dart';
import 'pill_button.dart';

class NameScheduleDialog extends StatefulWidget {
  final String title;
  final String placeholder;
  final String confirmLabel;
  final String? initialValue;

  const NameScheduleDialog({
    super.key,
    this.title = AppStrings.newScheduleTitle,
    this.placeholder = AppStrings.newSchedulePlaceholder,
    this.confirmLabel = AppStrings.create,
    this.initialValue,
  });

  static Future<String?> show(
    BuildContext context, {
    String title = AppStrings.newScheduleTitle,
    String placeholder = AppStrings.newSchedulePlaceholder,
    String confirmLabel = AppStrings.create,
    String? initialValue,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => NameScheduleDialog(
        title: title,
        placeholder: placeholder,
        confirmLabel: confirmLabel,
        initialValue: initialValue,
      ),
    );
  }

  @override
  State<NameScheduleDialog> createState() => _NameScheduleDialogState();
}

class _NameScheduleDialogState extends State<NameScheduleDialog> {
  late final TextEditingController _controller;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: appFont(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
              decoration: InputDecoration(
                hintText: widget.placeholder,
                filled: true,
                fillColor: const Color(0xFFF2F2F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _showError
                      ? const BorderSide(color: Colors.black, width: 1.5)
                      : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _showError
                      ? const BorderSide(color: Colors.black, width: 1.5)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _showError
                      ? const BorderSide(color: Colors.black, width: 1.5)
                      : const BorderSide(color: Colors.black, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: appFont(fontSize: 16),
            ),
            if (_showError) ...[ 
              const SizedBox(height: 6),
              Text(
                'Please enter a schedule name.',
                style: appFont(fontSize: 12, color: const Color(0xFFFF5252)),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: AppStrings.cancel,
                    background: const Color(0xFFF2F2F2),
                    textColor: Colors.black,
                    onTap: () => Navigator.pop(context, null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PillButton(
                    label: widget.confirmLabel,
                    background: const Color(0xFF040505),
                    textColor: Colors.white,
                    onTap: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.pop(context, text);
                      } else if (widget.initialValue != null) {
                        // rename mode — empty = cancel
                        Navigator.pop(context, null);
                      } else {
                        // create mode — show inline error
                        setState(() => _showError = true);
                      }
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
