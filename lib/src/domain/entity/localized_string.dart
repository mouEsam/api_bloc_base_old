import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LocalizedString extends Equatable {
  final String defaultLang;
  final Map<String, String> data;

  const LocalizedString(this.defaultLang, this.data);

  factory LocalizedString.create(
      {String? arabic,
      String? english,
      Map<String, String>? data,
      Map<Locale, String>? localeData,
      Locale? defaultLocale,
      String? defaultLanguage}) {
    Map<String, String> actualData = {};
    if (data?.isNotEmpty == true) {
      actualData.addAll(data!);
    }
    if (localeData?.isNotEmpty == true) {
      actualData.addAll(
          localeData!.map((key, value) => MapEntry(key.languageCode, value)));
    }
    if (arabic != null) {
      actualData['ar'] = arabic;
    }
    if (english != null) {
      actualData['en'] = english;
    }
    String _defaultLanguage =
        defaultLanguage ?? defaultLocale?.languageCode ?? 'en';
    if (actualData.isNotEmpty && !actualData.containsKey(_defaultLanguage)) {
      _defaultLanguage = actualData.entries.first.key;
    }
    // actualData.removeWhere((key, value) => value == null);
    actualData = actualData.map((key, value) => MapEntry(key, value.trim()));
    actualData.removeWhere((key, value) => value.isEmpty);
    return LocalizedString(_defaultLanguage, actualData);
  }

  bool get exist => data.isNotEmpty;

  String of(BuildContext context, {bool noEmpty = true}) {
    final locale = Localizations.localeOf(context);
    return forLocale(locale, noEmpty: noEmpty);
  }

  String forLocale(Locale locale, {bool noEmpty = true}) {
    return forLang(locale.languageCode, noEmpty: noEmpty);
  }

  String forLang(String lang, {bool noEmpty = true}) {
    String? result = data.containsKey(lang) ? data[lang] : data[defaultLang];
    if (result == null && data.isNotEmpty) {
      result = data.values.first;
    }
    if (result?.isEmpty == true && noEmpty) {
      result = data.values
          .firstWhere((element) => element.isNotEmpty, orElse: () => '');
    }
    return result ?? '';
  }

  @override
  List<Object?> get props => [data, defaultLang];
}
