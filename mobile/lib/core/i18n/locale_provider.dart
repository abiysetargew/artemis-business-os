import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported app locales.
enum AppLocale { english, amharic }

extension AppLocaleX on AppLocale {
  String get code => switch (this) {
    AppLocale.english => 'en',
    AppLocale.amharic => 'am',
  };

  String get displayName => switch (this) {
    AppLocale.english => 'English',
    AppLocale.amharic => 'አማርኛ',
  };

  String get nativeFlag => switch (this) {
    AppLocale.english => '🇬🇧',
    AppLocale.amharic => '🇪🇹',
  };

  Locale get materialLocale => Locale(code);
}

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier() : super(AppLocale.english) {
    _load();
  }

  static const _prefsKey = 'app_locale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == 'am') state = AppLocale.amharic;
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.code);
  }

  Future<void> toggle() async {
    final next = state == AppLocale.english
        ? AppLocale.amharic
        : AppLocale.english;
    await setLocale(next);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>(
  (ref) => LocaleNotifier(),
);

/// Centralised translation table. Only nav labels and section headings
/// are translated per product decision — forms remain in English.
class AppStrings {
  AppStrings._(this.locale);

  final AppLocale locale;

  static AppStrings of(BuildContext context) {
    final loc = Localizations.of(context, _AppLocaleData);
    return AppStrings._(loc?.locale ?? AppLocale.english);
  }

  static AppStrings ofLocale(AppLocale locale) => AppStrings._(locale);

  String _t(String en, String am) => locale == AppLocale.amharic ? am : en;

  // Bottom navigation
  String get navHome => _t('Home', 'መነሻ');
  String get navSales => _t('Sales', 'ሽያጭ');
  String get navCustomers => _t('Customers', 'ደንበኞች');
  String get navInventory => _t('Inventory', 'ክምችት');

  // Common section headings
  String get headingDashboard => _t('Dashboard', 'ዳሽቦርድ');
  String get headingReports => _t('Reports & Analytics', 'ሪፖርቶችና ትንተና');
  String get headingSettings => _t('Settings', 'ቅንብሮች');

  // Common actions
  String get actionSave => _t('Save', 'አስቀምጥ');
  String get actionCancel => _t('Cancel', 'ሰርዝ');
  String get actionDelete => _t('Delete', 'ሰርዝ');
  String get actionEdit => _t('Edit', 'አስተካክል');
  String get actionCreate => _t('Create', 'ፍጠር');
  String get actionRefresh => _t('Refresh', 'አድስ');
  String get actionSearch => _t('Search', 'ፈልግ');
  String get actionFilter => _t('Filter', 'አጣራ');

  // Status / payment
  String get statusPaid => _t('PAID', 'ተከፍሏል');
  String get statusPending => _t('PENDING', 'በመጠባበቅ ላይ');
  String get statusVerified => _t('VERIFIED', 'ተረጋግጧል');
  String get statusRejected => _t('REJECTED', 'ውድቅ ተደርጓል');

  // Top-level brand wordmark
  String get brandArtemis => _t('Artemis', 'አርቴሚስ');
  String get brandSubtitle => _t('BUSINESS OS', 'የንግድ ስርዓት');

  // Auth
  String get authSignIn => _t('Sign in', 'ግባ');
  String get authSignInSubtitle => _t('Sign in to continue', 'ለመቀጠል ይግቡ');
}

class _AppLocaleData extends LocalizationsDelegate<AppLocale> {
  const _AppLocaleData();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'am';

  @override
  Future<AppLocale> load(Locale locale) async {
    return locale.languageCode == 'am' ? AppLocale.amharic : AppLocale.english;
  }

  @override
  bool shouldReload(_AppLocaleData old) => false;
}

class AppLocalizations {
  static const delegate = _AppLocaleData();
}
