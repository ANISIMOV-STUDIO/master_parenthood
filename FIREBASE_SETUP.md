# Настройка Firebase для Master Parenthood

## Android настройка

1. Перейдите в [Firebase Console](https://console.firebase.google.com/)
2. Создайте новый проект или выберите существующий
3. Добавьте Android приложение:
   - Package name: `com.example.master_parenthood`
   - App nickname: `Master Parenthood`
4. Скачайте файл `google-services.json`
5. Поместите файл в папку `android/app/`

## iOS настройка

1. В том же проекте Firebase добавьте iOS приложение:
   - Bundle ID: `com.example.masterParenthood`
   - App nickname: `Master Parenthood iOS`
2. Скачайте файл `GoogleService-Info.plist`
3. Поместите файл в папку `ios/Runner/`

## Настройка в коде

После добавления файлов конфигурации:

1. Для Android - файл уже настроен в `android/app/build.gradle.kts`
2. Для iOS - добавьте файл в Xcode проект

## Тестирование

```bash
# Android
flutter run -d android

# iOS (требуется Mac)
flutter run -d ios
```

## Примечания

- Убедитесь, что в Firebase Console включена аутентификация по email/password
- Для Firestore создайте базу данных в тестовом режиме
- Для продакшена настройте правила безопасности Firestore 