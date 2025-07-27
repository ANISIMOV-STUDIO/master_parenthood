# Настройка для мобильных устройств

## Текущий статус

✅ **Web версия** - работает с мок-сервисами
✅ **Android** - настроен, требует Firebase конфигурации
✅ **iOS** - настроен, требует Firebase конфигурации

## Для тестирования на Android

### Вариант 1: Эмулятор Android Studio
1. Откройте Android Studio
2. Запустите AVD Manager
3. Создайте новый эмулятор или используйте существующий
4. Запустите эмулятор
5. Выполните: `flutter run -d android`

### Вариант 2: Физическое устройство
1. Подключите Android устройство по USB
2. Включите режим разработчика и USB отладку
3. Выполните: `flutter run -d android`

## Для тестирования на iOS (требуется Mac)

1. Установите Xcode
2. Подключите iPhone или запустите iOS Simulator
3. Выполните: `flutter run -d ios`

## Настройка Firebase для продакшена

1. Создайте проект в [Firebase Console](https://console.firebase.google.com/)
2. Добавьте Android и iOS приложения
3. Скачайте конфигурационные файлы:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
4. Замените мок-сервисы на реальные в коде

## Тестовые данные

Для входа в приложение используйте:
- Email: `test@example.com`
- Password: `password`

## Команды для разработки

```bash
# Запуск на Web
flutter run -d edge

# Запуск на Android
flutter run -d android

# Запуск на iOS
flutter run -d ios

# Сборка APK
flutter build apk

# Сборка для App Store
flutter build ios
```

## Примечания

- Приложение работает в демо-режиме с мок-данными
- Для полной функциональности нужна настройка Firebase
- AI функции требуют настройки OpenAI API ключей 