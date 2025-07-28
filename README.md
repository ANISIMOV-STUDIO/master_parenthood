# Master Parenthood 🌟

AI-powered парenting ассистент для современных родителей. Приложение помогает отслеживать развитие ребенка, генерировать персонализированные сказки, получать советы от ИИ и многое другое.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 📱 Функции

- **🤖 AI Ассистент** - Персонализированные советы по воспитанию
- **📚 Генератор сказок** - Уникальные истории для вашего ребенка
- **📊 Трекинг развития** - Отслеживание роста, веса и вех развития
- **🦄 Виртуальный питомец** - Мотивация для детей
- **🏆 Система достижений** - Геймификация родительства
- **🌍 Мультиязычность** - 5 языков (RU, EN, ES, FR, DE)
- **🌓 Темная тема** - Комфорт для глаз

## 🚀 Быстрый старт

### Требования

- Flutter 3.0+
- Dart 3.0+
- Firebase проект
- API ключи (OpenAI, VK, Яндекс)

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
- Создайте проект в [Firebase Console](https://console.firebase.google.com)
- Скачайте конфигурационные файлы:
    - `google-services.json` → `android/app/`
    - `GoogleService-Info.plist` → `ios/Runner/`

4. **Настройте переменные окружения**
```bash
flutter run --dart-define=OPENAI_API_KEY=your_key \
           --dart-define=VK_APP_ID=your_vk_id \
           --dart-define=YANDEX_CLIENT_ID=your_yandex_id
```

Подробнее: [ENVIRONMENT_SETUP.md](ENVIRONMENT_SETUP.md)

5. **Запустите приложение**
```bash
flutter run
```

## 📋 Архитектура

```
lib/
├── main.dart                 # Точка входа
├── screens/                  # UI экраны
│   ├── auth_screen.dart     # Авторизация
│   ├── home_screen.dart     # Главный экран
│   └── child_profile_screen.dart # Профиль ребенка
├── services/                 # Бизнес-логика
│   ├── firebase_service.dart # Firebase интеграция
│   └── ai_service.dart      # OpenAI интеграция
├── providers/               # State management
│   ├── auth_provider.dart   # Авторизация
│   └── locale_provider.dart # Локализация
└── l10n/                    # Переводы
    └── app_localizations.dart
```

## 🔧 Конфигурация

### Firebase

1. **Authentication**
    - Email/Password ✅
    - Google Sign-In ✅
    - Facebook Login ✅
    - VK (через Functions) 🔧
    - Яндекс (через Functions) 🔧

2. **Firestore структура**
```
users/
  {userId}/
    - profile data
    - activeChildId
    children/
      {childId}/
        - child data
    stories/
      {storyId}/
        - story data
    achievements/
      {achievementId}/
        - achievement data
```

3. **Storage**
    - Фото пользователей
    - Фото детей
    - Изображения для сказок

### API ключи

| Сервис | Получить ключ | Переменная |
|--------|--------------|------------|
| OpenAI | [platform.openai.com](https://platform.openai.com) | `OPENAI_API_KEY` |
| VK | [vk.com/dev](https://vk.com/dev) | `VK_APP_ID` |
| Яндекс | [oauth.yandex.ru](https://oauth.yandex.ru) | `YANDEX_CLIENT_ID` |

## 🎨 Кастомизация

### Темы
```dart
// lib/main.dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.purple, // Ваш цвет
  ),
)
```

### Языки
Добавьте переводы в `lib/l10n/app_localizations.dart`

### Достижения
Настройте в `lib/main.dart` → `AchievementData`

## 📦 Сборка

### Android

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release --dart-define=OPENAI_API_KEY=key
```

**App Bundle:**
```bash
flutter build appbundle --release --dart-define=OPENAI_API_KEY=key
```

### iOS

```bash
flutter build ios --release --dart-define=OPENAI_API_KEY=key
```

Подробнее: [ANDROID_RELEASE_SETUP.md](ANDROID_RELEASE_SETUP.md)

## 🧪 Тестирование

```bash
# Unit тесты
flutter test

# Integration тесты
flutter test integration_test

# Анализ кода
flutter analyze
```

## 🐛 Известные проблемы

1. **VK/Яндекс авторизация** - Требует настройки Firebase Functions
2. **AR функции** - В разработке
3. **Сообщество** - Планируется в v2.0

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit изменения (`git commit -m 'Add AmazingFeature'`)
4. Push в branch (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

## 📄 Лицензия

Распространяется под лицензией MIT. См. `LICENSE` для подробностей.

## 👥 Команда

- **Разработка** - Ваше имя
- **Дизайн** - Имя дизайнера
- **AI консультант** - Claude (Anthropic)

## 📞 Поддержка

- Email: support@masterparenthood.app
- Telegram: @masterparenthood
- Issues: [GitHub Issues](https://github.com/yourusername/master-parenthood/issues)

## 🎯 Roadmap

### v1.1
- [ ] Интеграция с умными весами
- [ ] Экспорт данных в PDF
- [ ] Виджеты для главного экрана

### v2.0
- [ ] Сообщество родителей
- [ ] Видео-консультации
- [ ] AR измерение роста
- [ ] Интеграция с детскими садами

## 💡 Благодарности

- [Flutter](https://flutter.dev) - За отличный фреймворк
- [Firebase](https://firebase.google.com) - За backend инфраструктуру
- [OpenAI](https://openai.com) - За AI возможности
- Всем родителям - За вдохновение

---

<p align="center">
  Сделано с ❤️ для родителей и их детей
</p>