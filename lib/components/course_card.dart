import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_text_styles.dart';

/// Course list item — shown on Screen 1 (today's classes) and Screen 3
/// (grouped-by-day list). Background is filled with the course's own
/// color; tapping the pencil icon opens the Course Editor in edit mode.
class CourseCard extends StatelessWidget {
  final String title;
  final Color color;
  final String timeRange;
  final String? room;
  final String? modeLabel;
  final VoidCallback onEditTap;

  const CourseCard({
    super.key,
    required this.title,
    required this.color,
    required this.timeRange,
    this.room,
    this.modeLabel,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: appFont(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              GestureDetector(
                onTap: onEditTap,
                child: const Icon(Icons.edit_outlined, size: 18, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Text(timeRange, style: appFont(fontSize: 12)),
            ],
          ),
          if (room != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: accentColor),
                const SizedBox(width: 6),
                Text(room!, style: appFont(fontSize: 12)),
              ],
            ),
          ],
          if (modeLabel != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                modeLabel!,
                style: appFont(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
