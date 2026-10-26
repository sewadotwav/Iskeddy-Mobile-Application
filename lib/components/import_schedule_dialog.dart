import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/schedule_share_service.dart';
import '../screens/screen3_detail/schedule_detail_screen.dart';
import 'app_text_styles.dart';
import 'app_toast.dart';
import 'pill_button.dart';

class ImportScheduleDialog extends StatefulWidget {
  final String deviceId;

  const ImportScheduleDialog({
    super.key,
    required this.deviceId,
  });

  static Future<void> show(BuildContext context, {required String deviceId}) {
    return showDialog<void>(
      context: context,
      builder: (context) => ImportScheduleDialog(deviceId: deviceId),
    );
  }

  @override
  State<ImportScheduleDialog> createState() => _ImportScheduleDialogState();
}

class _ImportScheduleDialogState extends State<ImportScheduleDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      setState(() {
        _controller.text = text;
        _errorMessage = null;
      });
    } else {
      if (mounted) {
        AppToast.show(context, 'Clipboard is empty.');
      }
    }
  }

  Future<void> _processImport() async {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty) {
      setState(() {
        _errorMessage = 'Please paste an export code to import.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final newScheduleId = await ScheduleShareService.importAndSaveToFirestore(
        deviceId: widget.deviceId,
        base64Code: rawText,
      );

      if (newScheduleId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid or corrupted export code format.';
        });
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      AppToast.show(
        context,
        'Schedule successfully imported and saved!',
      );

      // Navigate straight to the new schedule
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScheduleDetailScreen(scheduleId: newScheduleId),
        ),
      );
    } catch (e) {
      debugPrint('Error importing schedule: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save imported schedule. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Import Schedule',
                    style: appFont(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Paste the Iskeddy export code shared by your classmate below to load their timetable:',
              style: appFont(
                fontSize: 13,
                color: const Color(0xFF8A8A8A),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 4,
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              style: appFont(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Paste export code here...',
                hintStyle: appFont(fontSize: 13, color: const Color(0xFFB0B0B0)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _errorMessage != null
                      ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
                      : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _errorMessage != null
                      ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _errorMessage != null
                      ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
                      : const BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste_rounded, size: 14, color: accentColor),
                label: Text(
                  'Paste from Clipboard',
                  style: appFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFEF4444),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: appFont(
                          fontSize: 12,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: 'Cancel',
                    background: const Color(0xFFF2F2F2),
                    textColor: accentColor,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isLoading
                      ? Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : PillButton(
                          label: 'Import',
                          background: accentColor,
                          textColor: Colors.white,
                          onTap: _processImport,
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
