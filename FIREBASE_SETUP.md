# Полное руководство по настройке Firebase для Master Parenthood

## Оглавление
1. [Создание проекта Firebase](#создание-проекта-firebase)
2. [Настройка Android](#настройка-android)
3. [Настройка iOS](#настройка-ios)
4. [Настройка аутентификации](#настройка-аутентификации)
5. [Настройка Firestore](#настройка-firestore)
6. [Настройка Storage](#настройка-storage)
7. [Настройка социальных сетей](#настройка-социальных-сетей)
8. [Firebase Functions для VK и Яндекс](#firebase-functions-для-vk-и-яндекс)

## Создание проекта Firebase

1. Перейдите в [Firebase Console](https://console.firebase.google.com/)
2. Нажмите "Create a project" или "Создать проект"
3. Введите название проекта: `Master Parenthood`
4. Включите Google Analytics (опционально)
5. Выберите аккаунт Analytics
6. Нажмите "Create project"

## Настройка Android

### 1. Добавление Android приложения

1. В консоли Firebase нажмите на иконку Android
2. Заполните данные:
   - **Android package name**: `com.example.master_parenthood`
   - **App nickname**: `Master Parenthood Android`
   - **Debug signing certificate SHA-1** (опционально, но нужно для Google Sign-In):
     ```bash
     # Для debug версии
     cd android
     ./gradlew signingReport
     # Найдите SHA1 в выводе для варианта :app:signingReport
     ```

### 2. Загрузка и размещение google-services.json

1. Скачайте файл `google-services.json`
2. Поместите его в папку `android/app/`

### 3. Настройка build.gradle

Файл `android/build.gradle.kts` уже настроен, но убедитесь, что есть:
```kotlin
// В android/build.gradle.kts
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

Файл `android/app/build.gradle.kts` должен содержать:
```kotlin
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
}
```

## Настройка iOS

### 1. Добавление iOS приложения

1. В консоли Firebase нажмите "Add app" → iOS
2. Заполните данные:
   - **iOS bundle ID**: `com.example.masterParenthood`
   - **App nickname**: `Master Parenthood iOS`
   - **App Store ID** (опционально)

### 2. Загрузка и размещение GoogleService-Info.plist

1. Скачайте файл `GoogleService-Info.plist`
2. Откройте проект в Xcode:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```
3. Перетащите `GoogleService-Info.plist` в папку `Runner` в Xcode
4. Убедитесь, что выбрано "Copy items if needed" и "Runner" в target

### 3. Настройка Info.plist

Добавьте в `ios/Runner/Info.plist`:
```xml
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Замените на ваш REVERSED_CLIENT_ID из GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>

<!-- Facebook Login -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbYOUR_FACEBOOK_APP_ID</string>
        </array>
    </dict>
</array>
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>Master Parenthood</string>

<!-- LSApplicationQueriesSchemes for external apps -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
    <string>vk</string>
    <string>vk-share</string>
    <string>vkauthorize</string>
</array>
```

## Настройка аутентификации

### 1. Email/Password

1. В Firebase Console перейдите в Authentication
2. Нажмите "Get started"
3. Во вкладке "Sign-in method" включите "Email/Password"

### 2. Google Sign-In

1. Во вкладке "Sign-in method" включите "Google"
2. Укажите "Project support email"
3. Сохраните изменения

### 3. Facebook Login

1. Создайте приложение в [Facebook Developers](https://developers.facebook.com/)
2. Получите App ID и App Secret
3. В Firebase Console включите "Facebook" в Sign-in methods
4. Вставьте App ID и App Secret
5. Скопируйте OAuth redirect URI и добавьте в настройки Facebook App

### 4. Настройка VK (VKontakte)

VK требует custom authentication через Firebase Functions.

1. Создайте приложение в [VK Developers](https://vk.com/dev)
2. Получите App ID
3. Настройте Firebase Functions (см. раздел ниже)

### 5. Настройка Яндекс

Яндекс также требует custom authentication.

1. Создайте приложение в [Яндекс OAuth](https://oauth.yandex.ru/)
2. Получите Client ID и Client Secret
3. Настройте Firebase Functions (см. раздел ниже)

## Настройка Firestore

### 1. Создание базы данных

1. В Firebase Console перейдите в Firestore Database
2. Нажмите "Create database"
3. Выберите режим:
   - **Test mode** для разработки (30 дней открытый доступ)
   - **Production mode** для продакшена (требует настройки правил)
4. Выберите локацию (например, europe-west3)

### 2. Правила безопасности

Для продакшена используйте следующие правила в Firestore:

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
      
      // Уведомления пользователя
      match /notifications/{notificationId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 3. Индексы

Создайте следующие составные индексы:

1. Коллекция: `users/{userId}/stories`
   - Поля: `childId` (Ascending), `createdAt` (Descending)

2. Коллекция: `users/{userId}/children`
   - Поля: `createdAt` (Ascending)

## Настройка Storage

### 1. Активация Storage

1. В Firebase Console перейдите в Storage
2. Нажмите "Get started"
3. Примите правила безопасности по умолчанию
4. Выберите локацию

### 2. Правила безопасности Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Пользователи могут загружать только в свою папку
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Настройка социальных сетей

### Google Sign-In

1. Убедитесь, что SHA-1 добавлен в Firebase
2. Для iOS убедитесь, что REVERSED_CLIENT_ID добавлен в Info.plist

### Facebook

1. В [Facebook Developers](https://developers.facebook.com/):
   - Добавьте платформы Android и iOS
   - Для Android: добавьте package name и SHA-1
   - Для iOS: добавьте Bundle ID
   - Включите Facebook Login

### VK (VKontakte)

1. В [VK Developers](https://vk.com/dev):
   - Создайте Standalone-приложение
   - Получите ID приложения
   - В настройках укажите redirect URI

### Яндекс

1. В [Яндекс OAuth](https://oauth.yandex.ru/):
   - Создайте приложение
   - Получите Client ID
   - Настройте Callback URL

## Firebase Functions для VK и Яндекс

### 1. Инициализация Functions

```bash
npm install -g firebase-tools
firebase login
firebase init functions
```

### 2. Код для VK аутентификации

Создайте файл `functions/src/vk-auth.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

export const createVKCustomToken = functions.https.onCall(async (data, context) => {
  const { userId, accessToken, email } = data;
  
  // Верификация токена VK
  try {
    const response = await axios.get('https://api.vk.com/method/users.get', {
      params: {
        user_ids: userId,
        access_token: accessToken,
        v: '5.131'
      }
    });
    
    if (response.data.response && response.data.response[0]) {
      // Создаем custom token
      const customToken = await admin.auth().createCustomToken(userId, {
        provider: 'vk.com',
        email: email
      });
      
      // Создаем/обновляем пользователя в Firestore
      const userRef = admin.firestore().collection('users').doc(userId);
      await userRef.set({
        provider: 'vk.com',
        vkId: userId,
        email: email,
        lastLogin: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      
      return { customToken };
    } else {
      throw new Error('Invalid VK token');
    }
  } catch (error) {
    throw new functions.https.HttpsError('unauthenticated', 'Invalid VK credentials');
  }
});
```

### 3. Код для Яндекс аутентификации

Создайте файл `functions/src/yandex-auth.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

export const createYandexCustomToken = functions.https.onCall(async (data, context) => {
  const { userId, accessToken } = data;
  
  // Верификация токена Яндекс
  try {
    const response = await axios.get('https://login.yandex.ru/info', {
      headers: {
        'Authorization': `OAuth ${accessToken}`
      }
    });
    
    if (response.data && response.data.id) {
      // Создаем custom token
      const customToken = await admin.auth().createCustomToken(response.data.id, {
        provider: 'yandex.ru',
        email: response.data.default_email
      });
      
      // Создаем/обновляем пользователя в Firestore
      const userRef = admin.firestore().collection('users').doc(response.data.id);
      await userRef.set({
        provider: 'yandex.ru',
        yandexId: response.data.id,
        email: response.data.default_email,
        displayName: response.data.real_name || response.data.display_name,
        lastLogin: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      
      return { customToken };
    } else {
      throw new Error('Invalid Yandex token');
    }
  } catch (error) {
    throw new functions.https.HttpsError('unauthenticated', 'Invalid Yandex credentials');
  }
});
```

### 4. Деплой Functions

```bash
firebase deploy --only functions
```

## Обновление кода приложения

### 1. Обновите URL в Firebase Service

В файле `lib/services/firebase_service.dart` замените:

```dart
// Замените на ваш URL Firebase Functions
final response = await http.post(
  Uri.parse('https://YOUR-PROJECT.cloudfunctions.net/createVKCustomToken'),
  // ...
);
```

### 2. Обновите ключи социальных сетей

В файле `lib/screens/auth_screen.dart`:

```dart
// VK
const vkAppId = 'YOUR_VK_APP_ID';
const redirectUri = 'https://your-app.com/vk-callback';

// Яндекс
const yandexClientId = 'YOUR_YANDEX_CLIENT_ID';
const redirectUri = 'https://your-app.com/yandex-callback';
```

## Тестирование

### 1. Локальное тестирование

```bash
flutter run -d android
# или
flutter run -d ios
```

### 2. Проверка Firebase

1. Authentication - проверьте появление пользователей
2. Firestore - проверьте создание документов
3. Storage - проверьте загрузку фото

## Чеклист перед продакшеном

- [ ] Переключить Firestore в Production mode
- [ ] Настроить правила безопасности
- [ ] Добавить production SHA-1 для Android
- [ ] Настроить App Check (опционально)
- [ ] Включить Cloud Functions billing
- [ ] Проверить квоты и лимиты
- [ ] Настроить мониторинг и алерты

## Полезные ссылки

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Firebase Status](https://status.firebase.google.com/)