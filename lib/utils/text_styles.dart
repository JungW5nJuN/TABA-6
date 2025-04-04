import 'package:flutter/material.dart';
import 'font_manager.dart';

class AppTextStyles {
  static Future<TextStyle> getTextStyle({
    required double fontSize,
    Color color = Colors.black,
    FontWeight fontWeight = FontWeight.normal,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) async {
    final fontFamily = await FontManager.getCurrentFont();
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }
} 