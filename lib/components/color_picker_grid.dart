import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ColorPickerGrid extends StatelessWidget {
  final List<Color> colors;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ColorPickerGrid({
    super.key,
    this.colors = courseColors,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final row1 = colors.sublist(0, 5);
    final row2 = colors.sublist(5, 10);
    
    Widget buildRow(List<Color> rowColors, int offset) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(rowColors.length, (index) {
          final i = offset + index;
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i],
                border: isSelected ? Border.all(color: accentColor, width: 1.6) : null,
              ),
              child: isSelected ? const Icon(Icons.check, size: 15, color: accentColor) : null,
            ),
          );
        }),
      );
    }

    return Column(
      children: [
        buildRow(row1, 0),
        const SizedBox(height: 12),
        buildRow(row2, 5),
      ],
    );
  }
}
