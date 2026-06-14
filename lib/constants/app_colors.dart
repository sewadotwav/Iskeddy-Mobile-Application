import 'package:flutter/material.dart';

/// Fixed palette of 9 colors available for course blocks.
/// Students select one of these when creating/editing a course.
const List<Color> courseColors = [
  Color(0xFFF9E9D0), // Light Orange
  Color(0xFFFFC498), // Pastel Orange
  Color(0xFFC5AB93), // Gray Orange
  Color(0xFFFEEDA8), // Light Yellow
  Color(0xFFB7CBC9), // Pastel Gray Turquoise
  Color(0xFFFFA726), // Light Red (orange-leaning)
  Color(0xFFC0B7CB), // Pastel Gray Lavender
  Color(0xFFC6D899), // Pastel Gray Yellow-Green
  Color(0xFFFFACAC), // Light Red (pink-leaning)
];

/// Use these when saving `colorHex` to Firestore.
const List<String> courseColorHexValues = [
  '#F9E9D0',
  '#FFC498',
  '#C5AB93',
  '#FEEDA8',
  '#B7CBC9',
  '#FFA726',
  '#C0B7CB',
  '#C6D899',
  '#FFACAC',
];

class AppPalette {
  static const Color background = Color(0xFFF5F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2E2E2E);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color divider = Color(0xFFE0E0E0);
}