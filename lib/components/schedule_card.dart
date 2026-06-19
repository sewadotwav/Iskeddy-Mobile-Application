import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'app_text_styles.dart';

/// Schedule list item for Screen 2 — handles both normal mode (bare
/// trash icon, no circular fill) and multi-select mode (selection
/// circle + highlighted border)
class ScheduleCard extends StatelessWidget {
  final String name;
  final int courseCount;
  final bool isPinned;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDeleteTap;
  final VoidCallback onSelectToggle;

  const ScheduleCard({
    super.key,
    required this.name,
    required this.courseCount,
    this.isPinned = false,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
    required this.onDeleteTap,
    required this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isMultiSelectMode ? onSelectToggle : onTap,
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: accentColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: courseColors[1], // mint
              ),
              child: const Icon(Icons.calendar_today_outlined, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: appFont(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$courseCount COURSES',
                      style: appFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isMultiSelectMode)
              _SelectionCircle(selected: isSelected)
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPinned)
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 6),
                      child: Icon(Icons.push_pin, size: 20, color: accentColor),
                    ),
                  GestureDetector(
                    onTap: onDeleteTap,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.delete_outline, size: 22, color: accentColor),
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

class _SelectionCircle extends StatelessWidget {
  final bool selected;

  const _SelectionCircle({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accentColor : Colors.transparent,
        border: Border.all(
          color: selected ? accentColor : const Color(0xFFD8D8D8),
          width: 1.6,
        ),
      ),
      child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }
}
