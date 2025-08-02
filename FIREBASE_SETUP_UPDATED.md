# Настройка Firebase для Master Parenthood

## Содержание
1. [Создание проекта Firebase](#создание-проекта-firebase)
2. [Настройка Android](#настройка-android)
3. [Настройка iOS](#настройка-ios)
4. [Firestore Database](#firestore-database)
5. [Authentication](#authentication)
6. [Storage](#storage)
7. [Настройка социальных сетей](#настройка-социальных-сетей)

## Создание проекта Firebase

1. Перейдите в [Firebase Console](https://console.firebase.google.com/)
2. Нажмите "Create a project" или "Создать проект"
3. Введите название проекта: `Master Parenthood`
4. Включите Google Analytics (опционально)
5. Выберите аккаунт Analytics
6. Нажмите "Create project"

## Настройка Android

### 1. Добавление Android приложения

1. В Firebase Console выберите ваш проект
2. Нажмите на иконку Android
3. Введите данные:
   - **Android package name**: `com.yourcompany.master_parenthood`
   - **App nickname**: Master Parenthood (опционально)
   - **Debug signing certificate SHA-1**: (для Google Sign-In)

### 2. Получение SHA-1

```bash
# Для debug версии
cd android
./gradlew signingReport

# Или через keytool
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 3. Скачивание конфигурации

1. Скачайте `google-services.json`
2. Поместите его в `android/app/`

### 4. Настройка build.gradle

**android/build.gradle:**
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

**android/app/build.gradle:**
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        minSdkVersion 21
        multiDexEnabled true
    }
}
```

## Настройка iOS

### 1. Добавление iOS приложения

1. В Firebase Console нажмите "Add app" → iOS
2. Введите **iOS bundle ID**: `com.yourcompany.masterParenthood`
3. **App nickname**: Master Parenthood (опционально)

### 2. Скачивание конфигурации

1. Скачайте `GoogleService-Info.plist`
2. Откройте `ios/` в Xcode
3. Перетащите файл в папку `Runner` в Xcode
4. Убедитесь, что "Copy items if needed" отмечено

### 3. Настройка Info.plist

Добавьте в `ios/Runner/Info.plist`:

```xml
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Скопируйте REVERSED_CLIENT_ID из GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## Firestore Database

### 1. Создание базы данных

1. В Firebase Console перейдите в Firestore Database
2. Нажмите "Create database"
3. Выберите режим:
   - **Production mode** - для продакшена
   - **Test mode** - для разработки (30 дней открытого доступа)
4. Выберите локацию (ближайшую к вашим пользователям)

### 2. Правила безопасности

Настройте правила в `Firestore Database → Rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователи могут читать и писать только свои данные
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Дети пользователя
      match /children/{childId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Истории пользователя
      match /stories/{storyId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Достижения пользователя
      match /achievements/{achievementId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 3. Индексы

Firebase автоматически предложит создать индексы при первом запросе. Также можно создать вручную:

1. Firestore Database → Indexes
2. Создайте составные индексы для:
   - `stories`: `childId` + `createdAt`
   - `children`: `createdAt`

## Authentication

### 1. Включение методов входа

1. Перейдите в Authentication → Sign-in method
2. Включите:
   - **Email/Password**
   - **Google**

### 2. Google Sign-In

1. При включении Google автоматически настроится
2. Убедитесь, что Web client ID настроен
3. Для iOS добавьте URL scheme в Info.plist (см. выше)

## Storage

### 1. Настройка Storage

1. Перейдите в Storage
2. Нажмите "Get started"
3. Выберите режим безопасности
4. Выберите локацию

### 2. Правила безопасности

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Пользователи могут загружать только в свою папку
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024 // Максимум 5MB
        && request.resource.contentType.matches('image/.*'); // Только изображения
    }
  }
}
```

## Настройка социальных сетей

### 1. Google Sign-In

Google Sign-In автоматически настраивается при включении в Firebase Authentication.

Дополнительные шаги:

1. Убедитесь, что SHA-1 добавлен в настройки Android приложения
2. Для production добавьте SHA-1 от release keystore
3. Проверьте настройки OAuth 2.0 в [Google Cloud Console](https://console.cloud.google.com/)

### 2. Дополнительная безопасность

Настройте домены авторизации:
1. Authentication → Settings → Authorized domains
2. Добавьте домены вашего приложения

## Переменные окружения

### 1. Локальная разработка

Создайте файл `.env` в корне проекта:

```bash
OPENAI_API_KEY=your_openai_api_key
```

### 2. Запуск с переменными

```bash
flutter run --dart-define=OPENAI_API_KEY="your_key"
```

### 3. CI/CD

Настройте секреты в вашей CI/CD системе:
- `OPENAI_API_KEY`
- `FIREBASE_TOKEN` (для деплоя)

## Мониторинг и аналитика

### 1. Firebase Analytics

Автоматически работает после настройки. События отслеживаются в коде:

```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'story_generated',
  parameters: {
    'theme': theme,
    'child_age': childAge,
  },
);
```

### 2. Crashlytics (опционально)

1. Добавьте в `pubspec.yaml`:
```yaml
firebase_crashlytics: ^3.4.8
```

2. Настройте в `main.dart`:
```dart
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
```

### 3. Performance Monitoring (опционально)

1. Добавьте в `pubspec.yaml`:
```yaml
firebase_performance: ^0.9.3+8
```

## Полезные команды

```bash
# Проверка конфигурации
flutterfire configure

# Обновление CLI
dart pub global activate flutterfire_cli

# Деплой правил Firestore
firebase deploy --only firestore:rules

# Деплой правил Storage
firebase deploy --only storage

# Эмулятор для локальной разработки
firebase emulators:start
```

## Troubleshooting

### Проблема: Google Sign-In не работает на Android
- Проверьте SHA-1 в Firebase Console
- Пересоздайте `google-services.json`
- Очистите кэш: `flutter clean`

### Проблема: iOS build fails
- Обновите pods: `cd ios && pod install`
- Проверьте минимальную версию iOS (должна быть 12.0+)

### Проблема: Firestore offline persistence
- Включите в коде:
```dart
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

## Чеклист перед релизом

- [ ] Настроить production правила Firestore
- [ ] Настроить production правила Storage
- [ ] Добавить SHA-1 от release keystore
- [ ] Настроить домены авторизации
- [ ] Включить App Check (опционально)
- [ ] Настроить резервное копирование Firestore
- [ ] Настроить мониторинг и алерты

## Дополнительные ресурсы

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Firebase Status](https://status.firebase.google.com/)