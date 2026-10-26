import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../models/course_model.dart';
import '../models/schedule_model.dart';
import '../services/schedule_share_service.dart';
import 'app_text_styles.dart';
import 'app_toast.dart';
import 'circular_icon_button.dart';

class ScheduleShareSheet extends StatelessWidget {
  final Schedule schedule;
  final List<Course> courses;
  final GlobalKey canvasKey;

  const ScheduleShareSheet({
    super.key,
    required this.schedule,
    required this.courses,
    required this.canvasKey,
  });

  static Future<void> show(
    BuildContext context, {
    required Schedule schedule,
    required List<Course> courses,
    required GlobalKey canvasKey,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => ScheduleShareSheet(
        schedule: schedule,
        courses: courses,
        canvasKey: canvasKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Schedule',
                      style: appFont(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule.name,
                      style: appFont(
                        fontSize: 13,
                        color: const Color(0xFF8A8A8A),
                      ),
                    ),
                  ],
                ),
                CircularIconButton(
                  icon: Icons.close,
                  primary: false,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Option 1: Share as Image
            _ShareOptionTile(
              icon: Icons.image_outlined,
              title: 'Share as Image',
              subtitle: 'Capture timetable card and share with classmates',
              onTap: () async {
                Navigator.of(context).pop();
                AppToast.show(context, 'Generating schedule image...');
                final success = await ScheduleShareService.shareScheduleImage(
                  canvasKey,
                  schedule.name,
                );
                if (!success && context.mounted) {
                  AppToast.show(context, 'Could not capture schedule image.');
                }
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Copy Export Code
            _ShareOptionTile(
              icon: Icons.code_rounded,
              title: 'Copy Export Code',
              subtitle: 'Copy code so another Iskeddy user can import it',
              onTap: () async {
                final code = ScheduleShareService.exportScheduleToJson(
                  schedule,
                  courses,
                );
                if (code.isEmpty) {
                  AppToast.show(context, 'Failed to generate export code.');
                  return;
                }
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                Navigator.of(context).pop();
                AppToast.show(context, 'Export code copied to clipboard!');
              },
            ),
            const SizedBox(height: 12),

            // Option 3: Share Export Code via Share Sheet
            _ShareOptionTile(
              icon: Icons.send_rounded,
              title: 'Share Code Directly',
              subtitle: 'Send the export text via WhatsApp, Messages, or Email',
              onTap: () async {
                final code = ScheduleShareService.exportScheduleToJson(
                  schedule,
                  courses,
                );
                if (code.isEmpty) {
                  AppToast.show(context, 'Failed to generate export code.');
                  return;
                }
                Navigator.of(context).pop();
                await Share.share(
                  'Here is my Iskeddy schedule export code for "${schedule.name}":\n\n$code',
                  subject: '${schedule.name} Schedule Export Code',
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7F7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: appFont(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: appFont(
                        fontSize: 12,
                        color: const Color(0xFF8A8A8A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFC4C4C4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
