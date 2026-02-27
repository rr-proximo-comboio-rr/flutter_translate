import 'package:flutter/widgets.dart';
import 'package:flutter_translate_fix/flutter_translate_fix.dart';
import 'package:flutter_translate_fix/src/constants/constants.dart';
import 'package:flutter_translate_fix/src/services/locale_service.dart';
import 'package:flutter_translate_fix/src/validators/configuration_validator.dart';
import 'package:intl/intl.dart';

class LocalizationDelegate extends LocalizationsDelegate<Localization> {
  final Locale fallbackLocale;

  final List<Locale> supportedLocales;

  final Map<Locale, String> supportedLocalesMap;

  final MissingTranslationStrategy missingKeyStrategy;

  LocaleChangedCallback? onLocaleChanged;

  LocalizationDelegate._(
    this.fallbackLocale,
    this.supportedLocales,
    this.supportedLocalesMap,
    this.missingKeyStrategy,
  );

  static late Locale _currentLocale;

  Locale get currentLocale => _currentLocale;

  Future<void> changeLocale(Locale newLocale) async {
    final locale =
        LocaleService.findLocale(newLocale, supportedLocales) ?? fallbackLocale;

    if (_currentLocale == locale) return;

    await _loadLocalizedContent(locale);

    _currentLocale = locale;

    Intl.defaultLocale = _currentLocale.languageCode;

    if (onLocaleChanged != null) {
      await onLocaleChanged!(locale);
    }
  }

  /// Creates and initializes a [LocalizationDelegate].
  ///
  /// This method handles the complete setup of the localization system.
  /// It ensures bindings are initialized, loads locale maps from assets,
  /// validates the configuration, and loads the initial translations.
  ///
  /// The method automatically sets the initial locale based on the device's
  /// preferred language if it is supported; otherwise, it defaults to
  /// [fallbackLocale].
  ///
  /// Example usage:
  /// ```dart
  /// final delegate = await LocalizationDelegate.create(
  ///   fallbackLocale: 'en',
  ///   supportedLocales: ['en', 'es', 'fr'],
  /// );
  /// ```
  ///
  /// Parameters:
  /// - [fallbackLocale]: The default locale code (e.g., 'en_US') used when
  ///   a translation is missing or the device locale is not supported.
  ///   This must be present in [supportedLocales].
  /// - [supportedLocales]: A list of locale codes that the application
  ///   supports (e.g., `['en', 'es', 'fr']`).
  /// - [basePath]: The asset path where localization files are stored.
  ///   Defaults to [Constants.localizedAssetsPath].
  /// - [missingTranslationStrategy]: The strategy to handle missing keys
  ///   (e.g., show the key or fallback to the default language).
  ///   Defaults to [MissingTranslationStrategy.KEY].
  ///
  /// Returns a [Future] that resolves to a fully initialized [LocalizationDelegate].
  static Future<LocalizationDelegate> create({
    required String fallbackLocale,
    required List<String> supportedLocales,
    String basePath = Constants.localizedAssetsPath,
    MissingTranslationStrategy missingTranslationStrategy =
        MissingTranslationStrategy.KEY,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    final fallback = localeFromString(fallbackLocale);

    final localesMap = await LocaleService.getLocalesMap(
      supportedLocales,
      basePath,
    );
    final locales = localesMap.keys.toList();

    ConfigurationValidator.validate(fallback, locales);

    _currentLocale = LocaleService.loadDeviceLocale() ?? fallback;

    final instance = LocalizationDelegate._(
      fallback,
      locales,
      localesMap,
      missingTranslationStrategy,
    );

    await instance._loadLocalizedContent(_currentLocale);

    return instance;
  }

  @override
  Future<Localization> load(Locale newLocale) async {
    if (currentLocale != newLocale) {
      await changeLocale(newLocale);
    }

    return Localization.instance;
  }

  @override
  bool isSupported(Locale? locale) => locale != null;

  @override
  bool shouldReload(LocalizationsDelegate<Localization> old) => true;

  Future<Map<String, dynamic>?> _fallbackContent(Locale fallbackLocale) async {
    switch (missingKeyStrategy) {
      case MissingTranslationStrategy.KEY:
        return null;
      case MissingTranslationStrategy.FALLBACK:
        return await LocaleService.getLocaleContent(
          fallbackLocale,
          supportedLocalesMap,
        );
    }
  }

  Future<void> _loadLocalizedContent(Locale locale) async {
    final localizedContent = await LocaleService.getLocaleContent(
      locale,
      supportedLocalesMap,
    );

    final fallbackContent = await _fallbackContent(fallbackLocale);

    Localization.load(localizedContent, fallbackContent);
  }
}
