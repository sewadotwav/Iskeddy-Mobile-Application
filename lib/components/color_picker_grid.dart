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
    return GridView.count(
      crossAxisCount: 5,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(colors.length, (i) {
        final isSelected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: Container(
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
}
