# Master Parenthood 🌟

AI-powered парenting ассистент для современных родителей. Приложение помогает отслеживать развитие ребенка, генерировать персонализированные сказки, получать советы от ИИ и многое другое.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-brightgreen)
![License](https://img.shields.io/badge/License-MIT-green)

## 📱 Основные функции

### Реализовано ✅
- **🤖 AI Ассистент** - Персонализированные советы по воспитанию с учетом возраста ребенка
- **📚 Генератор сказок** - Уникальные истории на основе имени и интересов ребенка
- **👶 Профили детей** - Управление несколькими детьми с фото и данными
- **📊 Трекинг развития** - Отслеживание роста, веса и вех развития
- **🦄 Виртуальный питомец** - Интерактивный питомец с системой прогресса
- **🏆 Система достижений** - Геймификация родительства с XP и уровнями
- **🌍 Мультиязычность** - 5 языков (RU, EN, ES, FR, DE)
- **🌓 Темная тема** - Автоматическое переключение и ручная настройка
- **💾 Облачное хранение** - Синхронизация данных через Firebase
- **📸 Фото галерея** - Загрузка и хранение фото детей

### В разработке 🚧
- **📷 AR измерение роста** - Использование камеры для измерения
- **👥 Сообщество родителей** - Форум и чат для общения
- **🎮 Развивающие игры** - Интерактивные игры для детей
- **📅 Умный планировщик** - AI-рекомендации по распорядку дня
- **🏥 Трекер здоровья** - Прививки, визиты к врачу, лекарства

## 🚀 Быстрый старт

### Требования
- Flutter 3.0+
- Dart 3.0+
- Android Studio / Xcode
- Firebase аккаунт
- OpenAI API ключ (для AI функций)

### Установка

1. **Клонируйте репозиторий**
```bash
git clone https://github.com/yourusername/master-parenthood.git
cd master-parenthood
```

2. **Установите зависимости**
```bash
flutter pub get
```

3. **Настройте Firebase**

Следуйте инструкции в [FIREBASE_SETUP.md](FIREBASE_SETUP.md) для детальной настройки.

Краткая версия:
- Создайте проект в [Firebase Console](https://console.firebase.google.com)
- Скачайте конфигурационные файлы:
    - `google-services.json` → `android/app/`
    - `GoogleService-Info.plist` → `ios/Runner/`
- Включите Authentication, Firestore, Storage

4. **Настройте API ключи**

Создайте файл `run_dev.sh` (не коммитьте его!):
```bash
#!/bin/bash
flutter run \
  --dart-define=OPENAI_API_KEY="your_openai_key" \
  
```

Или используйте VS Code launch.json (см. [ENVIRONMENT_SETUP.md](ENVIRONMENT_SETUP.md))

5. **Запустите приложение**
```bash
# Для разработки
./run_dev.sh

# Или напрямую
flutter run --dart-define=OPENAI_API_KEY=your_key
```

## 📋 Архитектура проекта

```
lib/
├── main.dart                    # Точка входа, провайдеры, навигация
├── screens/                     # UI экраны
│   ├── auth_screen.dart        # Авторизация (Email, Google)
│   ├── home_screen.dart        # Главный экран с функциями
│   └── child_profile_screen.dart # Детальный профиль ребенка
├── services/                    # Бизнес-логика
│   ├── firebase_service.dart   # Работа с Firebase (Auth, Firestore, Storage)
│   └── ai_service.dart         # Интеграция с OpenAI
├── providers/                   # State management
│   ├── auth_provider.dart      # Состояние авторизации
│   └── locale_provider.dart    # Управление языком
└── l10n/                       # Локализация
    └── app_localizations.dart  # Переводы для 5 языков


```

## 🔧 Детальная настройка

### Авторизация

Приложение поддерживает несколько способов входа:
- **Email/Password** - базовая регистрация
- **Google Sign-In** - через Google аккаунт

### AI функции

Для работы AI ассистента и генератора сказок необходим OpenAI API ключ:

1. Получите ключ на [platform.openai.com](https://platform.openai.com)
2. Передайте его через `--dart-define=OPENAI_API_KEY=your_key`

Функции работают и без ключа, используя заготовленные ответы.

### База данных

Структура Firestore:
```
users/
  {userId}/
    - email, displayName, photoURL
    - level, xp, subscription
    - activeChildId
    children/
      {childId}/
        - name, birthDate, gender
        - height, weight, photoURL
        - petName, petType, petStats
    stories/
      {storyId}/
        - childId, theme, story
        - createdAt, isFavorite
    achievements/
      {achievementId}/
        - unlocked, progress, unlockedAt
```

## 🎨 Кастомизация

### Изменение темы
```dart
// lib/main.dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.purple, // Измените основной цвет
  ),
)
```

### Добавление языка
1. Добавьте переводы в `lib/l10n/app_localizations.dart`
2. Добавьте locale в `supportedLocales` в main.dart

### Новые достижения
Добавьте в `lib/main.dart` → `AchievementsScreen` → `achievements` список

## 📦 Сборка для публикации

### Android

```bash
# Debug APK для тестирования
flutter build apk --debug

# Release APK
flutter build apk --release \
  --dart-define=OPENAI_API_KEY=key

# App Bundle для Google Play
flutter build appbundle --release \
  --dart-define=OPENAI_API_KEY=key
```

Подробная инструкция: [ANDROID_RELEASE_SETUP.md](ANDROID_RELEASE_SETUP.md)

### iOS

```bash
flutter build ios --release \
  --dart-define=OPENAI_API_KEY=key
```

Затем откройте Xcode и создайте архив для App Store.

## 🧪 Тестирование

```bash
# Unit тесты
flutter test

# Анализ кода
flutter analyze

# Проверка форматирования
flutter format --dry-run .
```

## 📈 Метрики и аналитика

Приложение автоматически собирает:
- Firebase Analytics - поведение пользователей
- Crashlytics - отчеты об ошибках (опционально)
- Performance Monitoring - производительность (опционально)

## 🤝 Вклад в проект

Мы приветствуем ваш вклад! См. [CONTRIBUTING.md](CONTRIBUTING.md) для деталей.

1. Fork репозитория
2. Создайте feature branch
3. Commit изменения
4. Push в branch
5. Откройте Pull Request

## 📄 Лицензия

Распространяется под лицензией MIT. См. [LICENSE](LICENSE) для деталей.

## 🆘 Поддержка

- **Документация**: [Wiki](https://github.com/yourusername/master-parenthood/wiki)
- **Баг-репорты**: [Issues](https://github.com/yourusername/master-parenthood/issues)
- **Обсуждения**: [Discussions](https://github.com/yourusername/master-parenthood/discussions)
- **Email**: support@masterparenthood.app

## 🎯 Roadmap

### v1.1 (Q1 2025)
- [ ] AR измерение роста
- [ ] Экспорт данных в PDF
- [ ] Виджеты для iOS/Android
- [ ] Интеграция с Apple Health / Google Fit

### v2.0 (Q2 2025)
- [ ] Сообщество родителей
- [ ] Видео-консультации с экспертами
- [ ] AI анализ фото для отслеживания развития
- [ ] Интеграция с детскими садами/школами

### v3.0 (Q3 2025)
- [ ] Marketplace для детских товаров
- [ ] AI-помощник для выбора игрушек/книг
- [ ] Семейный календарь с напоминаниями
- [ ] Мультиаккаунт для всей семьи

---

<p align="center">
  Сделано с ❤️ для родителей и их детей
</p>