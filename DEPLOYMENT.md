# Deployment Guide для Master Parenthood

## 📋 Содержание

1. [Подготовка к деплою](#подготовка-к-деплою)
2. [Firebase Functions](#firebase-functions)
3. [Android](#android)
4. [iOS](#ios)
5. [CI/CD](#cicd)
6. [Мониторинг](#мониторинг)

## 🚀 Подготовка к деплою

### Чеклист перед деплоем

- [ ] Все тесты проходят
- [ ] Версия обновлена в `pubspec.yaml`
- [ ] CHANGELOG обновлен
- [ ] API ключи настроены для продакшена
- [ ] Firebase правила безопасности настроены
- [ ] Аналитика и крэш-репорты включены

### Версионирование

В `pubspec.yaml`:
```yaml
version: 1.0.0+1  # major.minor.patch+buildNumber
```

- **major**: Большие изменения, несовместимые с предыдущей версией
- **minor**: Новые функции, обратно совместимые
- **patch**: Исправления багов
- **buildNumber**: Увеличивается с каждой сборкой

## 🔥 Firebase Functions

### 1. Установка Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### 2. Настройка функций
```bash
cd functions
npm install
```

### 3. Конфигурация
```bash
# Установите переменные окружения
firebase functions:config:set \
  vk.app_id="YOUR_VK_APP_ID" \
  vk.app_secret="YOUR_VK_APP_SECRET" \
  yandex.client_id="YOUR_YANDEX_CLIENT_ID" \
  yandex.client_secret="YOUR_YANDEX_CLIENT_SECRET"
```

### 4. Деплой
```bash
# Только функции
firebase deploy --only functions

# Конкретная функция
firebase deploy --only functions:createVKCustomToken

# С эмулятором для тестирования
firebase emulators:start --only functions
```

### 5. Мониторинг функций
```bash
# Логи
firebase functions:log

# Логи конкретной функции
firebase functions:log --only createVKCustomToken
```

## 🤖 Android

### 1. Подготовка ключей

Создайте `key.properties` в `android/`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/path/to/your/keystore.jks
```

### 2. Сборка для Google Play

#### App Bundle (рекомендуется)
```bash
flutter build appbundle --release \
  --dart-define=OPENAI_API_KEY=prod_key \
  --dart-define=VK_APP_ID=prod_vk_id \
  --dart-define=YANDEX_CLIENT_ID=prod_yandex_id
```

#### APK для тестирования
```bash
flutter build apk --release \
  --dart-define=OPENAI_API_KEY=prod_key \
  --split-per-abi
```

### 3. Загрузка в Google Play Console

1. Перейдите в [Play Console](https://play.google.com/console)
2. Выберите приложение
3. Release → Production → Create new release
4. Загрузите `.aab` файл
5. Заполните release notes
6. Submit for review

### 4. Настройки в Play Console

- [ ] Заполните описание приложения
- [ ] Загрузите скриншоты (минимум 2)
- [ ] Добавьте feature graphic
- [ ] Настройте content rating
- [ ] Заполните privacy policy
- [ ] Настройте pricing & distribution

## 🍎 iOS

### 1. Подготовка в Xcode

```bash
cd ios
pod install
open Runner.xcworkspace
```

### 2. Настройка подписи

1. Выберите Runner в навигаторе
2. Вкладка Signing & Capabilities
3. Выберите Team
4. Убедитесь, что Bundle Identifier правильный

### 3. Сборка архива

```bash
flutter build ios --release \
  --dart-define=OPENAI_API_KEY=prod_key \
  --dart-define=VK_APP_ID=prod_vk_id \
  --dart-define=YANDEX_CLIENT_ID=prod_yandex_id
```

### 4. Загрузка в App Store Connect

1. В Xcode: Product → Archive
2. Дождитесь завершения
3. Window → Organizer
4. Выберите архив → Distribute App
5. App Store Connect → Next
6. Upload → Next
7. Дождитесь валидации
8. Upload

### 5. Настройки в App Store Connect

- [ ] Создайте новую версию
- [ ] Загрузите скриншоты для всех размеров
- [ ] Заполните описание и what's new
- [ ] Настройте возрастной рейтинг
- [ ] Добавьте privacy policy URL
- [ ] Submit for review

## 🔄 CI/CD

### GitHub Actions

Создайте `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-java@v3
        with:
          java-version: '11'
          
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Build APK
        run: |
          flutter build apk --release \
            --dart-define=OPENAI_API_KEY=${{ secrets.OPENAI_API_KEY }} \
            --dart-define=VK_APP_ID=${{ secrets.VK_APP_ID }} \
            --dart-define=YANDEX_CLIENT_ID=${{ secrets.YANDEX_CLIENT_ID }}
            
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
          
      - name: Install dependencies
        run: |
          flutter pub get
          cd ios && pod install
          
      - name: Build iOS
        run: |
          flutter build ios --release --no-codesign \
            --dart-define=OPENAI_API_KEY=${{ secrets.OPENAI_API_KEY }} \
            --dart-define=VK_APP_ID=${{ secrets.VK_APP_ID }} \
            --dart-define=YANDEX_CLIENT_ID=${{ secrets.YANDEX_CLIENT_ID }}
```

### Fastlane

#### Android (`android/fastlane/Fastfile`)
```ruby
default_platform(:android)

platform :android do
  desc "Deploy to Play Store"
  lane :deploy do
    gradle(
      task: "bundle",
      build_type: "Release"
    )
    
    upload_to_play_store(
      track: 'production',
      aab: '../build/app/outputs/bundle/release/app-release.aab'
    )
  end
end
```

#### iOS (`ios/fastlane/Fastfile`)
```ruby
default_platform(:ios)

platform :ios do
  desc "Deploy to App Store"
  lane :deploy do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner"
    )
    
    upload_to_app_store(
      skip_waiting_for_build_processing: true
    )
  end
end
```

## 📊 Мониторинг

### 1. Firebase Analytics

События для отслеживания:
```dart
// В коде
FirebaseAnalytics.instance.logEvent(
  name: 'story_generated',
  parameters: {
    'theme': theme,
    'child_age': childAge,
  },
);
```

### 2. Crashlytics

```bash
# Добавьте зависимость
flutter pub add firebase_crashlytics

# В main.dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

### 3. Performance Monitoring

```bash
# Добавьте зависимость
flutter pub add firebase_performance

# Отслеживайте кастомные метрики
final trace = FirebasePerformance.instance.newTrace('story_generation');
await trace.start();
// ... ваш код ...
await trace.stop();
```

### 4. Дашборд метрик

Отслеживайте в Firebase Console:
- **Crash-free users**: > 99.5%
- **Daily Active Users**: Рост
- **User engagement**: > 5 минут
- **Story generation**: > 3 в день
- **Retention**: D1 > 60%, D7 > 40%, D30 > 25%

## 🚨 Rollback план

Если что-то пошло не так:

### Android
1. В Play Console: Release → Production
2. Выберите предыдущую версию
3. "Promote to production"

### iOS
1. В App Store Connect невозможен rollback
2. Подготовьте hotfix версию
3. Запросите expedited review

### Firebase Functions
```bash
# Посмотреть историю деплоев
firebase functions:list

# Вернуться к предыдущей версии
firebase deploy --only functions --project production
```

## 📝 Post-deployment чеклист

- [ ] Проверить работу всех функций в продакшене
- [ ] Убедиться, что аналитика работает
- [ ] Проверить crash reports
- [ ] Мониторить отзывы первые 24 часа
- [ ] Подготовить hotfix при необходимости
- [ ] Обновить статус в PROJECT_STATUS.md

---

Удачного деплоя! 🚀