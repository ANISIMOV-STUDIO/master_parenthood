# Настройка Android для релиза

## Создание ключа подписи

### 1. Генерация keystore

```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Вам будут заданы вопросы:
- **Keystore password**: придумайте надежный пароль
- **Key password**: можно использовать тот же пароль
- **Имя и фамилия**: ваше имя или название компании
- **Organizational unit**: отдел (можно оставить пустым)
- **Organization**: название организации
- **City**: город
- **State**: область/штат
- **Country code**: код страны (RU для России)

### 2. Сохраните keystore

Переместите файл в безопасное место:
```bash
mkdir ~/android-keys
mv ~/key.jks ~/android-keys/upload-keystore.jks
```

⚠️ **ВАЖНО**: Никогда не коммитьте keystore в Git!

## Настройка проекта

### 1. Создайте файл key.properties

Создайте файл `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/YOUR_USERNAME/android-keys/upload-keystore.jks
```

### 2. Добавьте в .gitignore

Добавьте в `android/.gitignore`:
```
key.properties
**/*.keystore
**/*.jks
```

### 3. Обновите build.gradle.kts

В файле `android/app/build.gradle.kts` добавьте перед `android {`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

В секции `android` добавьте:

```kotlin
android {
    // ... другие настройки ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            
            // Включить ProGuard/R8 для уменьшения размера
            isMinifyEnabled = true
            isShrinkResources = true
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 4. Создайте proguard-rules.pro

Создайте файл `android/app/proguard-rules.pro`:

```pro
# Flutter specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Your app specific
-keep class com.example.master_parenthood.** { *; }
```

## Сборка релизной версии

### 1. APK файл

```bash
flutter build apk --release
```

Файл будет в: `build/app/outputs/flutter-apk/app-release.apk`

### 2. App Bundle (рекомендуется для Google Play)

```bash
flutter build appbundle --release
```

Файл будет в: `build/app/outputs/bundle/release/app-release.aab`

### 3. Split APK (для уменьшения размера)

```bash
flutter build apk --split-per-abi --release
```

Создаст отдельные APK для каждой архитектуры:
- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`

## Оптимизация размера

### 1. Анализ размера APK

```bash
flutter build apk --analyze-size
```

### 2. Удаление неиспользуемых ресурсов

В `android/app/build.gradle.kts`:
```kotlin
android {
    buildTypes {
        release {
            shrinkResources true
            minifyEnabled true
        }
    }
}
```

### 3. Оптимизация изображений

- Используйте WebP вместо PNG/JPG
- Сжимайте изображения
- Используйте векторные drawable где возможно

## Настройка для Google Play

### 1. Версионирование

В `pubspec.yaml`:
```yaml
version: 1.0.0+1  # version: major.minor.patch+buildNumber
```

### 2. Минимальная версия Android

В `android/app/build.gradle.kts`:
```kotlin
defaultConfig {
    minSdk = 21  // Android 5.0 (рекомендуется)
    targetSdk = 34  // Последняя версия
}
```

### 3. Разрешения

Проверьте `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Только необходимые разрешения -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## Тестирование релизной версии

### 1. Установка на устройство

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 2. Проверьте:
- [ ] Работу без отладочного режима
- [ ] Производительность
- [ ] Размер приложения
- [ ] Все функции работают корректно
- [ ] Нет крашей

## Подготовка к публикации

### 1. Скриншоты для Google Play

Необходимые размеры:
- Телефон: 1080 x 1920
- 7" планшет: 1024 x 600
- 10" планшет: 1280 x 800

### 2. Графические ресурсы

- Иконка: 512 x 512 (PNG)
- Feature graphic: 1024 x 500
- Promo graphic: 180 x 120 (опционально)

### 3. Тексты

- Краткое описание (80 символов)
- Полное описание (4000 символов)
- Что нового (500 символов)

## Безопасность

### 1. Бэкап ключей

```bash
# Создайте зашифрованный архив
tar -czf - ~/android-keys | openssl enc -aes-256-cbc -salt -out android-keys-backup.tar.gz.enc
```

### 2. Храните в безопасном месте:
- Keystore файл
- Пароли
- key.properties
- Google Play upload certificate

### 3. App Signing by Google Play

Рекомендуется использовать для дополнительной безопасности.

## Чеклист перед релизом

- [ ] Keystore создан и сохранен
- [ ] key.properties настроен
- [ ] build.gradle обновлен
- [ ] ProGuard правила добавлены
- [ ] Версия обновлена
- [ ] Разрешения проверены
- [ ] APK/AAB собран
- [ ] Приложение протестировано
- [ ] Графика подготовлена
- [ ] Описания написаны
- [ ] Бэкап ключей создан

## Команды для CI/CD

Для автоматической сборки:

```bash
# Установка переменных окружения
export KEYSTORE_PATH=/path/to/keystore.jks
export KEYSTORE_PASSWORD=your_password
export KEY_ALIAS=upload
export KEY_PASSWORD=your_key_password

# Сборка
flutter build appbundle --release
```