import 'package:flutter_translate_fix/src/constants/constants.dart';
import 'package:intl/intl.dart';

enum MissingTranslationStrategy { KEY, FALLBACK }

class Localization {
  Localization._();

  late Map<String, dynamic> _translations;

  Map<String, dynamic>? _fallbackTranslations;

  static Localization? _instance;

  static Localization get instance =>
      _instance ?? (_instance = Localization._());

  static void load(
    Map<String, dynamic> translations, [
    Map<String, dynamic>? fallbackTranslations,
  ]) {
    instance._translations = translations;
    instance._fallbackTranslations = fallbackTranslations;
  }

  String translate(String key, {Map<String, dynamic>? args}) {
    String? translation = _translate(key, _translations, args: args);

    if (translation == null && _fallbackTranslations != null) {
      translation = _translate(key, _fallbackTranslations!, args: args);
    }

    return translation ?? key;
  }

  String? _translate(
    String key,
    Map<String, dynamic> translations, {
    Map<String, dynamic>? args,
  }) {
    String? translation = _getTranslation(key, translations);

    if (translation != null && args != null) {
      translation = _assignArguments(translation, args);
    }

    return translation;
  }

  String _assignArguments(String value, Map<String, dynamic> args) {
    for (final key in args.keys) {
      value = value.replaceAll('{$key}', '${args[key]}');
    }

    return value;
  }

  String? _getTranslation(String key, Map<String, dynamic> map) {
    final keys = key.split('.');

    if (keys.length > 1) {
      final firstKey = keys.first;

      if (map.containsKey(firstKey) && map[firstKey] is! String) {
        return _getTranslation(
          key.substring(key.indexOf('.') + 1),
          map[firstKey],
        );
      }
    }

    return map[key];
  }

  String plural(String key, num value, {Map<String, dynamic>? args}) {
    Map<String, String>? fallbackForms;
    if (_fallbackTranslations != null) {
      fallbackForms = _getAllPluralForms(key, _fallbackTranslations!);
    }

    final primaryForms = _getAllPluralForms(key, _translations);

    final forms = <String, String>{
      ...?fallbackForms,
      ...?primaryForms,
    };

    return Intl.plural(
      value,
      zero: _putArgs(forms[Constants.pluralZero], value, args: args),
      one: _putArgs(forms[Constants.pluralOne], value, args: args),
      two: _putArgs(forms[Constants.pluralTwo], value, args: args),
      few: _putArgs(forms[Constants.pluralFew], value, args: args),
      many: _putArgs(forms[Constants.pluralMany], value, args: args),
      other: _putArgs(forms[Constants.pluralOther], value, args: args) ??
          '$key.${Constants.pluralOther}',
    );
  }

  String? _putArgs(String? template, num value, {Map<String, dynamic>? args}) {
    if (template == null) {
      return null;
    }

    template = template.replaceAll(Constants.pluralValueArg, value.toString());

    if (args == null) {
      return template;
    }

    for (String k in args.keys) {
      template = template!.replaceAll("{$k}", args[k].toString());
    }

    return template;
  }

  Map<String, String>? _getAllPluralForms(
      String key, Map<String, dynamic> map) {
    final keys = key.split('.');

    if (keys.length > 1) {
      final firstKey = keys.first;

      if (map.containsKey(firstKey) && map[firstKey] is! String) {
        return _getAllPluralForms(
          key.substring(key.indexOf('.') + 1),
          map[firstKey],
        );
      }
    }

    if (!map.containsKey(key) || map[key] is! Map) return null;

    final result = <String, String>{};
    final pluralMap = map[key] as Map<String, dynamic>;

    for (final k in pluralMap.keys) {
      result[k] = pluralMap[k].toString();
    }

    return result;
  }
}
