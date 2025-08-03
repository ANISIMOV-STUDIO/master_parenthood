# 🚨 Быстрое исправление Firebase ошибок

## Проблема: PERMISSION_DENIED и "Cloud Firestore API has not been used"

### ⚡ Срочное решение (2 минуты):

1. **Откройте Firebase Console**
   ```
   https://console.firebase.google.com/project/master-parenthood
   ```

2. **Включите Firestore API**
   - Перейдите в раздел **Firestore Database**
   - Нажмите **Create database**
   - Выберите **Start in test mode** (для разработки)
   - Выберите регион **europe-west** (ближе к России)

3. **Настройте правила безопасности**
   ```javascript
   // Firestore Security Rules
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Разрешаем все операции для авторизованных пользователей
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

4. **Включите Authentication**
   - Перейдите в **Authentication** → **Sign-in method**
   - Включите **Google** и **Email/Password**

### 🔧 Альтернативное решение (если нет доступа к Firebase Console):

```dart
// Добавьте в main.dart для работы в offline режиме
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Включаем offline persistence
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Настройки для работы offline
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  runApp(MyApp());
}
```

### 📱 Проверка результата:
После выполнения исправлений должны исчезнуть:
- ❌ `PERMISSION_DENIED` ошибки
- ❌ `Frame drops` 24-815ms
- ❌ `Unhandled Exception` в консоли
- ❌ `service is currently unavailable`

### ✅ Ожидаемый результат:
- 🚀 Плавная работа 60fps
- 🌐 Стабильное соединение с Firebase  
- 💾 Offline режим при потере сети
- 🎯 Мгновенная навигация через кэш

---
**Время выполнения:** ~2 минуты  
**Приоритет:** Критический 🔥