# Инструкция по удалению всех мок-сервисов

## Файлы для удаления

Удалите следующие файлы:

1. `lib/services/mock_firebase_service.dart` - мок-сервис Firebase
2. `lib/services/platform_firebase_service.dart` - платформо-зависимый сервис
3. `lib/services/real_firebase_service.dart` - дублирующий сервис

## Обновления кода

### 1. Обновите main.dart

Удалите все импорты мок-сервисов и замените на:
```dart
import 'services/firebase_service.dart';
```

### 2. Обновите все экраны

Во всех файлах замените:
- `mock_firebase.MockFirebaseService` → `FirebaseService`
- `platform_firebase.PlatformFirebaseService` → `FirebaseService`
- Удалите все проверки `if (kIsWeb)`

### 3. Пример обновления home_screen.dart

**Было:**
```dart
if (kIsWeb) {
  await mock_firebase.MockFirebaseService.addXP(10);
} else {
  await platform_firebase.PlatformFirebaseService.addXP(10);
}
```

**Стало:**
```dart
await FirebaseService.addXP(10);
```

### 4. Обновите auth_screen.dart

**Было:**
```dart
if (kIsWeb) {
  await mock_firebase.MockFirebaseService.signInWithEmail(
    email: email,
    password: password,
  );
} else {
  await platform_firebase.PlatformFirebaseService.signInWithEmail(
    email: email,
    password: password,
  );
}
```

**Стало:**
```dart
await FirebaseService.signInWithEmail(
  email: email,
  password: password,
);
```

## Проверка

После удаления всех моков:

1. Убедитесь, что проект компилируется без ошибок
2. Проверьте, что все функции работают с реальным Firebase
3. Протестируйте авторизацию через все провайдеры
4. Проверьте загрузку изображений в Storage

## Итоговая структура

После удаления моков у вас должна остаться следующая структура:

```
lib/
├── services/
│   ├── firebase_service.dart     # Основной сервис Firebase
│   └── ai_service.dart          # Сервис для работы с AI
├── screens/
│   ├── auth_screen.dart         # Экран авторизации
│   ├── home_screen.dart         # Главный экран
│   └── child_profile_screen.dart # Профиль ребенка
└── main.dart                    # Точка входа
```

## Преимущества удаления моков

1. **Упрощение кода** - один сервис вместо трех
2. **Меньше условной логики** - нет проверок платформы
3. **Единообразие** - одинаковое поведение на всех платформах
4. **Проще поддержка** - меньше кода для обновления

## Важно!

Перед удалением моков убедитесь, что:
- Firebase проект полностью настроен
- Все ключи и конфигурации добавлены
- Приложение успешно работает с реальным Firebase