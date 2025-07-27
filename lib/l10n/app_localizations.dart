// lib/l10n/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Переводы
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'home': 'Home',
      'child': 'Child',
      'achievements': 'Awards',
      'community': 'Community',

      // Home screen
      'app_title': 'Master Parenthood',
      'hello': 'Hello! What\'s for today?',
      'level': 'Level',

      // Features
      'ai_assistant': 'AI Tips',
      'ar_height': 'AR Height',
      'challenges': 'Challenges',
      'stories': 'Stories',
      'topic_of_day': 'Topic',
      'daily_plan': 'Plan',
      'development': 'Growth',
      'games': 'Games',
      'health': 'Health',

      // Story generator
      'story_generator': 'Story Generator',
      'child_name': 'Child\'s name',
      'story_theme': 'Story theme',
      'story_hint': 'E.g.: dragons, space, princesses...',
      'generate_story': 'Create Story',
      'generating': 'Creating magic...',

      // Child profile
      'age': 'Age',
      'virtual_pet': 'Virtual Pet',
      'happiness': 'Happiness',
      'energy': 'Energy',
      'knowledge': 'Knowledge',
      'milestones': 'Development Milestones',
      'growth_chart': 'Growth Chart',

      // Stats
      'height_cm': 'cm',
      'weight_kg': 'kg',
      'years': 'years',
      'words': 'words',

      // Settings
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'notifications': 'Notifications',
      'sign_out': 'Sign Out',

      // Messages
      'coming_soon': 'coming soon!',
      'error': 'Something went wrong',
      'loading': 'Loading...',
    },
    'ru': {
      // Навигация
      'home': 'Главная',
      'child': 'Ребенок',
      'achievements': 'Награды',
      'community': 'Общение',

      // Главный экран
      'app_title': 'Мастер Родительства',
      'hello': 'Привет! Что сегодня?',
      'level': 'Уровень',

      // Функции
      'ai_assistant': 'ИИ-советы',
      'ar_height': 'AR-рост',
      'challenges': 'Челленджи',
      'stories': 'Сказки',
      'topic_of_day': 'Тема дня',
      'daily_plan': 'План дня',
      'development': 'Развитие',
      'games': 'Игры',
      'health': 'Здоровье',

      // Генератор сказок
      'story_generator': 'Генератор сказок',
      'child_name': 'Имя ребенка',
      'story_theme': 'Тема сказки',
      'story_hint': 'Например: драконы, космос, принцессы...',
      'generate_story': 'Создать сказку',
      'generating': 'Создаю волшебство...',

      // Профиль ребенка
      'age': 'Возраст',
      'virtual_pet': 'Виртуальный питомец',
      'happiness': 'Счастье',
      'energy': 'Энергия',
      'knowledge': 'Знания',
      'milestones': 'Вехи развития',
      'growth_chart': 'График роста',

      // Статистика
      'height_cm': 'см',
      'weight_kg': 'кг',
      'years': 'года',
      'words': 'слов',

      // Настройки
      'settings': 'Настройки',
      'dark_mode': 'Темная тема',
      'language': 'Язык',
      'notifications': 'Уведомления',
      'sign_out': 'Выйти',

      // Сообщения
      'coming_soon': 'скоро будет доступен!',
      'error': 'Что-то пошло не так',
      'loading': 'Загрузка...',
    },
    'es': {
      // Navegación
      'home': 'Inicio',
      'child': 'Niño',
      'achievements': 'Logros',
      'community': 'Comunidad',

      // Pantalla principal
      'app_title': 'Maestro de Paternidad',
      'hello': '¡Hola! ¿Qué hay para hoy?',
      'level': 'Nivel',

      // Funciones
      'ai_assistant': 'Consejos IA',
      'ar_height': 'Altura AR',
      'challenges': 'Desafíos',
      'stories': 'Cuentos',
      'topic_of_day': 'Tema',
      'daily_plan': 'Plan',
      'development': 'Desarrollo',
      'games': 'Juegos',
      'health': 'Salud',

      // Generador de cuentos
      'story_generator': 'Generador de Cuentos',
      'child_name': 'Nombre del niño',
      'story_theme': 'Tema del cuento',
      'story_hint': 'Ej: dragones, espacio, princesas...',
      'generate_story': 'Crear Cuento',
      'generating': 'Creando magia...',

      // Perfil del niño
      'age': 'Edad',
      'virtual_pet': 'Mascota Virtual',
      'happiness': 'Felicidad',
      'energy': 'Energía',
      'knowledge': 'Conocimiento',
      'milestones': 'Hitos del Desarrollo',
      'growth_chart': 'Gráfico de Crecimiento',

      // Estadísticas
      'height_cm': 'cm',
      'weight_kg': 'kg',
      'years': 'años',
      'words': 'palabras',

      // Configuración
      'settings': 'Ajustes',
      'dark_mode': 'Modo Oscuro',
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'sign_out': 'Cerrar Sesión',

      // Mensajes
      'coming_soon': '¡próximamente!',
      'error': 'Algo salió mal',
      'loading': 'Cargando...',
    },
    'fr': {
      // Navigation
      'home': 'Accueil',
      'child': 'Enfant',
      'achievements': 'Récompenses',
      'community': 'Communauté',

      // Écran principal
      'app_title': 'Maître Parentalité',
      'hello': 'Bonjour! Quoi aujourd\'hui?',
      'level': 'Niveau',

      // Fonctionnalités
      'ai_assistant': 'Conseils IA',
      'ar_height': 'Taille AR',
      'challenges': 'Défis',
      'stories': 'Histoires',
      'topic_of_day': 'Sujet',
      'daily_plan': 'Plan',
      'development': 'Développement',
      'games': 'Jeux',
      'health': 'Santé',

      // Générateur d'histoires
      'story_generator': 'Générateur d\'Histoires',
      'child_name': 'Nom de l\'enfant',
      'story_theme': 'Thème de l\'histoire',
      'story_hint': 'Ex: dragons, espace, princesses...',
      'generate_story': 'Créer Histoire',
      'generating': 'Création de magie...',

      // Profil de l'enfant
      'age': 'Âge',
      'virtual_pet': 'Animal Virtuel',
      'happiness': 'Bonheur',
      'energy': 'Énergie',
      'knowledge': 'Connaissance',
      'milestones': 'Étapes de Développement',
      'growth_chart': 'Courbe de Croissance',

      // Statistiques
      'height_cm': 'cm',
      'weight_kg': 'kg',
      'years': 'ans',
      'words': 'mots',

      // Paramètres
      'settings': 'Paramètres',
      'dark_mode': 'Mode Sombre',
      'language': 'Langue',
      'notifications': 'Notifications',
      'sign_out': 'Déconnexion',

      // Messages
      'coming_soon': 'bientôt disponible!',
      'error': 'Quelque chose a mal tourné',
      'loading': 'Chargement...',
    },
    'de': {
      // Navigation
      'home': 'Start',
      'child': 'Kind',
      'achievements': 'Erfolge',
      'community': 'Gemeinschaft',

      // Hauptbildschirm
      'app_title': 'Elternmeister',
      'hello': 'Hallo! Was gibt\'s heute?',
      'level': 'Stufe',

      // Funktionen
      'ai_assistant': 'KI-Tipps',
      'ar_height': 'AR-Größe',
      'challenges': 'Herausforderungen',
      'stories': 'Geschichten',
      'topic_of_day': 'Thema',
      'daily_plan': 'Plan',
      'development': 'Entwicklung',
      'games': 'Spiele',
      'health': 'Gesundheit',

      // Geschichtengenerator
      'story_generator': 'Geschichtengenerator',
      'child_name': 'Name des Kindes',
      'story_theme': 'Thema der Geschichte',
      'story_hint': 'Z.B.: Drachen, Weltraum, Prinzessinnen...',
      'generate_story': 'Geschichte Erstellen',
      'generating': 'Zaubere...',

      // Kinderprofil
      'age': 'Alter',
      'virtual_pet': 'Virtuelles Haustier',
      'happiness': 'Glück',
      'energy': 'Energie',
      'knowledge': 'Wissen',
      'milestones': 'Entwicklungsmeilensteine',
      'growth_chart': 'Wachstumskurve',

      // Statistiken
      'height_cm': 'cm',
      'weight_kg': 'kg',
      'years': 'Jahre',
      'words': 'Wörter',

      // Einstellungen
      'settings': 'Einstellungen',
      'dark_mode': 'Dunkler Modus',
      'language': 'Sprache',
      'notifications': 'Benachrichtigungen',
      'sign_out': 'Abmelden',

      // Nachrichten
      'coming_soon': 'kommt bald!',
      'error': 'Etwas ist schief gelaufen',
      'loading': 'Wird geladen...',
    },
  };

  // Геттеры для всех переводов
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get child => _localizedValues[locale.languageCode]!['child']!;
  String get achievements => _localizedValues[locale.languageCode]!['achievements']!;
  String get community => _localizedValues[locale.languageCode]!['community']!;

  String get appTitle => _localizedValues[locale.languageCode]!['app_title']!;
  String get hello => _localizedValues[locale.languageCode]!['hello']!;
  String get level => _localizedValues[locale.languageCode]!['level']!;

  String get aiAssistant => _localizedValues[locale.languageCode]!['ai_assistant']!;
  String get arHeight => _localizedValues[locale.languageCode]!['ar_height']!;
  String get challenges => _localizedValues[locale.languageCode]!['challenges']!;
  String get stories => _localizedValues[locale.languageCode]!['stories']!;
  String get topicOfDay => _localizedValues[locale.languageCode]!['topic_of_day']!;
  String get dailyPlan => _localizedValues[locale.languageCode]!['daily_plan']!;
  String get development => _localizedValues[locale.languageCode]!['development']!;
  String get games => _localizedValues[locale.languageCode]!['games']!;
  String get health => _localizedValues[locale.languageCode]!['health']!;

  String get storyGenerator => _localizedValues[locale.languageCode]!['story_generator']!;
  String get childName => _localizedValues[locale.languageCode]!['child_name']!;
  String get storyTheme => _localizedValues[locale.languageCode]!['story_theme']!;
  String get storyHint => _localizedValues[locale.languageCode]!['story_hint']!;
  String get generateStory => _localizedValues[locale.languageCode]!['generate_story']!;
  String get generating => _localizedValues[locale.languageCode]!['generating']!;

  String get age => _localizedValues[locale.languageCode]!['age']!;
  String get virtualPet => _localizedValues[locale.languageCode]!['virtual_pet']!;
  String get happiness => _localizedValues[locale.languageCode]!['happiness']!;
  String get energy => _localizedValues[locale.languageCode]!['energy']!;
  String get knowledge => _localizedValues[locale.languageCode]!['knowledge']!;
  String get milestones => _localizedValues[locale.languageCode]!['milestones']!;
  String get growthChart => _localizedValues[locale.languageCode]!['growth_chart']!;

  String get heightCm => _localizedValues[locale.languageCode]!['height_cm']!;
  String get weightKg => _localizedValues[locale.languageCode]!['weight_kg']!;
  String get years => _localizedValues[locale.languageCode]!['years']!;
  String get words => _localizedValues[locale.languageCode]!['words']!;

  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get darkMode => _localizedValues[locale.languageCode]!['dark_mode']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get notifications => _localizedValues[locale.languageCode]!['notifications']!;
  String get signOut => _localizedValues[locale.languageCode]!['sign_out']!;

  String get comingSoon => _localizedValues[locale.languageCode]!['coming_soon']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ru', 'es', 'fr', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}