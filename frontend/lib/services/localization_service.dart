import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  String _currentLocale = 'fr'; // Langue par défaut
  Map<String, Map<String, String>> _localizedValues = {};
  final Map<String, String> _availableLocales = {
    'fr': 'Français',
    'en': 'English',
    'es': 'Español',
    'pt': 'Português',
    // Ajouter d'autres langues selon les besoins
  };

  String get currentLocale => _currentLocale;
  Map<String, String> get availableLocales => _availableLocales;

  Future<void> loadLocale(String locale) async {
    _currentLocale = locale;
    
    // Charger les traductions depuis les fichiers JSON
    String jsonString;
    try {
      jsonString = await rootBundle.loadString('assets/lang/$locale.json');
    } catch (e) {
      // Si le fichier n'existe pas, charger la langue par défaut
      jsonString = await rootBundle.loadString('assets/lang/fr.json');
      _currentLocale = 'fr';
    }
    
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    _localizedValues[_currentLocale] = Map<String, String>.from(jsonMap);
  }

  String translate(String key, {Map<String, String>? params}) {
    String translated = _localizedValues[_currentLocale]?[key] ?? key;
    
    // Remplacer les paramètres dans la traduction
    if (params != null) {
      params.forEach((placeholder, value) {
        translated = translated.replaceAll('{{${placeholder}}}', value);
      });
    }
    
    return translated;
  }

  // Méthodes pour les différentes sections de l'application
  String get home => translate('home');
  String get profile => translate('profile');
  String get services => translate('services');
  String get settings => translate('settings');
  String get search => translate('search');
  String get notifications => translate('notifications');
  String get appointments => translate('appointments');
  String get payments => translate('payments');
  String get chat => translate('chat');
  String get logout => translate('logout');
  String get login => translate('login');
  String get register => translate('register');
  String get welcome => translate('welcome');
  String get confirm => translate('confirm');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get back => translate('back');
  String get next => translate('next');
  String get previous => translate('previous');
  String get ok => translate('ok');
  String get error => translate('error');
  String get success => translate('success');
  
  // Traductions spécifiques au domaine
  String get findArtisan => translate('find_artisan');
  String get findMerchant => translate('find_merchant');
  String get bookAppointment => translate('book_appointment');
  String get makePayment => translate('make_payment');
  String get rateService => translate('rate_service');
  String get writeReview => translate('write_review');
  String get myOrders => translate('my_orders');
  String get myServices => translate('my_services');
  String get businessHours => translate('business_hours');
  String get location => translate('location');
  String get contact => translate('contact');
  String get about => translate('about');
  
  // Messages d'erreur et de succès
  String get errorLoading => translate('error_loading');
  String get successSaved => translate('success_saved');
  String get pleaseWait => translate('please_wait');
  String get noData => translate('no_data');
  String get retry => translate('retry');
  String get networkError => translate('network_error');
  String get serverError => translate('server_error');
  
  // Unités et formats
  String get currency => translate('currency');
  String get distanceUnit => translate('distance_unit');
  String get timeFormat => translate('time_format');
  String get dateFormat => translate('date_format');
  
  // Méthode pour obtenir la devise locale
  String getCurrencySymbol() {
    switch (_currentLocale) {
      case 'fr':
      case 'fr-FR':
        return '€';
      case 'en':
      case 'en-US':
        return '\$';
      case 'en-GB':
        return '£';
      case 'es':
        return '€';
      case 'pt':
        return 'R\$';
      default:
        return '€'; // Devise par défaut
    }
  }
  
  // Méthode pour formater les nombres selon la locale
  String formatNumber(num number) {
    // Cette méthode peut être étendue pour inclure un formatage spécifique à la locale
    return number.toString();
  }
  
  // Méthode pour formater les dates selon la locale
  String formatDate(DateTime date) {
    // Cette méthode peut être étendue pour inclure un formatage spécifique à la locale
    return date.toString();
  }
}