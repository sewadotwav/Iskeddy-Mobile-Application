import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

TextStyle appFont({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color color = accentColor,
  bool italic = false,
}) {
  return TextStyle(
    fontFamily: 'ZalandoSansSemiExpanded',
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color,
    decoration: TextDecoration.none,
  );
}
