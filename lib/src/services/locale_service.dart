import 'dart:convert';
import 'dart:ui';

import 'package:flutter_translate_fix/flutter_translate_fix.dart';

import 'locale_file_service.dart';

class LocaleService {
  const LocaleService._();

  static Future<Map<Locale, String>> getLocalesMap(
    List<String> locales,
    String basePath,
  ) async {
    final files = await LocaleFileService.getLocaleFiles(locales, basePath);

    return files.map((x, y) => MapEntry(localeFromString(x), y));
  }

  static Locale? findLocale(Locale? locale, List<Locale> supportedLocales) {
    Locale? existing = supportedLocales.firstWhereOrNull((e) => e == locale);

    if (existing != null) return existing;

    return supportedLocales.firstWhereOrNull(
      (e) => e.languageCode == locale?.languageCode,
    );
  }

  static Future<Map<String, dynamic>> getLocaleContent(
    Locale locale,
    Map<Locale, String> supportedLocales,
  ) async {
    final file = supportedLocales[locale];
    if (file == null) return {};

    final content = await LocaleFileService.getLocaleContent(file);
    if (content == null) return {};

    return json.decode(content);
  }

  static Locale? loadDeviceLocale() {
    try {
      return getCurrentLocale();
    } catch (e) {
      return null;
    }
  }
}
