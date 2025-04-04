import 'package:shared_preferences/shared_preferences.dart';

class FontManager {
  static const String _fontKey = 'appFontFamily';
  static String? _cachedFont;  // 메모리에 캐시된 폰트

  static Future<String> getCurrentFont() async {
    // 캐시된 폰트가 있으면 반환
    if (_cachedFont != null) {
      return _cachedFont!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _cachedFont = prefs.getString(_fontKey) ?? 'Roboto';
    return _cachedFont!;
  }
  
  static Future<void> setFont(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, fontFamily);
    _cachedFont = fontFamily;  // 캐시 업데이트
  }
} 