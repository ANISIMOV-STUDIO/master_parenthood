# Настройка переменных окружения для Master Parenthood

## Обзор

Приложение использует переменные окружения для безопасного хранения ключей API и конфигурации. Это позволяет не хранить чувствительные данные в коде.

## Необходимые переменные

### 1. OpenAI API Key
```bash
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
```
Получить ключ: https://platform.openai.com/api-keys

### 2. VK OAuth
```bash
VK_APP_ID=xxxxxxxx
```
Создать приложение: https://vk.com/dev

### 3. Яндекс OAuth
```bash
YANDEX_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
Создать приложение: https://oauth.yandex.ru/

### 4. Firebase Functions URL
```bash
FIREBASE_FUNCTIONS_URL=https://your-project.cloudfunctions.net
```

## Способы установки переменных

### Вариант 1: Использование --dart-define (Рекомендуется для разработки)

```bash
flutter run --dart-define=OPENAI_API_KEY=your_key_here \
           --dart-define=VK_APP_ID=your_vk_id \
           --dart-define=YANDEX_CLIENT_ID=your_yandex_id
```

### Вариант 2: Создание скрипта запуска

Создайте файл `run_dev.sh` (или `run_dev.bat` для Windows):

```bash
#!/bin/bash
flutter run \
  --dart-define=OPENAI_API_KEY="your_openai_key" \
  --dart-define=VK_APP_ID="your_vk_app_id" \
  --dart-define=YANDEX_CLIENT_ID="your_yandex_client_id" \
  --dart-define=FIREBASE_FUNCTIONS_URL="https://your-project.cloudfunctions.net"
```

Не забудьте добавить этот файл в `.gitignore`!

### Вариант 3: Использование .env файла

1. Создайте файл `.env` в корне проекта:
```env
OPENAI_API_KEY=your_key_here
VK_APP_ID=your_vk_id
YANDEX_CLIENT_ID=your_yandex_id
FIREBASE_FUNCTIONS_URL=https://your-project.cloudfunctions.net
```

2. Добавьте `.env` в `.gitignore`

3. Используйте пакет `flutter_dotenv` (требует дополнительной настройки)

### Вариант 4: Для VS Code

Создайте/обновите `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter Dev",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=OPENAI_API_KEY=your_key",
        "--dart-define=VK_APP_ID=your_vk_id",
        "--dart-define=YANDEX_CLIENT_ID=your_yandex_id"
      ]
    }
  ]
}
```

## Сборка для продакшена

### Android
```bash
flutter build apk --release \
  --dart-define=OPENAI_API_KEY=your_key \
  --dart-define=VK_APP_ID=your_vk_id \
  --dart-define=YANDEX_CLIENT_ID=your_yandex_id
```

### iOS
```bash
flutter build ios --release \
  --dart-define=OPENAI_API_KEY=your_key \
  --dart-define=VK_APP_ID=your_vk_id \
  --dart-define=YANDEX_CLIENT_ID=your_yandex_id
```

## Использование в CI/CD

### GitHub Actions
```yaml
- name: Build APK
  run: |
    flutter build apk --release \
      --dart-define=OPENAI_API_KEY=${{ secrets.OPENAI_API_KEY }} \
      --dart-define=VK_APP_ID=${{ secrets.VK_APP_ID }} \
      --dart-define=YANDEX_CLIENT_ID=${{ secrets.YANDEX_CLIENT_ID }}
```

### GitLab CI
```yaml
build_apk:
  script:
    - flutter build apk --release 
        --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY 
        --dart-define=VK_APP_ID=$VK_APP_ID 
        --dart-define=YANDEX_CLIENT_ID=$YANDEX_CLIENT_ID
```

## Альтернатива: Firebase Remote Config

Для продакшена рекомендуется использовать Firebase Remote Config:

1. Добавьте зависимость:
```yaml
dependencies:
  firebase_remote_config: ^4.3.8
```

2. Настройте в Firebase Console
3. Получайте ключи динамически:
```dart
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();
final apiKey = remoteConfig.getString('openai_api_key');
```

## Безопасность

### ⚠️ Важные правила:

1. **Никогда** не коммитьте ключи в Git
2. Добавьте в `.gitignore`:
   ```
   .env
   *.env
   run_dev.sh
   run_dev.bat
   ```
3. Используйте разные ключи для dev и prod
4. Регулярно ротируйте ключи
5. Ограничивайте права доступа API ключей

### Проверка на утечки

Перед коммитом всегда проверяйте:
```bash
git diff --staged | grep -E "(api_key|client_id|secret)"
```

## Troubleshooting

### Ключи не работают
1. Проверьте правильность ключей
2. Убедитесь, что используете правильный формат
3. Проверьте, что ключи активны

### Ошибка "API key not configured"
- Убедитесь, что правильно передаете --dart-define
- Перезапустите приложение после изменения

### VK/Яндекс авторизация не работает
- Проверьте настройки OAuth в консолях разработчиков
- Убедитесь, что redirect URI совпадают

## Контакты для получения ключей

- **OpenAI**: https://platform.openai.com
- **VK Dev**: https://vk.com/dev
- **Яндекс OAuth**: https://oauth.yandex.ru
- **Firebase**: https://console.firebase.google.com