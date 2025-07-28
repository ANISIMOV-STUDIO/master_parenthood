# Contributing to Master Parenthood

Спасибо за интерес к проекту Master Parenthood! Мы рады любому вкладу в развитие приложения.

## 📋 Содержание

- [Кодекс поведения](#кодекс-поведения)
- [Как я могу помочь?](#как-я-могу-помочь)
- [Процесс разработки](#процесс-разработки)
- [Стиль кода](#стиль-кода)
- [Коммиты](#коммиты)
- [Pull Requests](#pull-requests)
- [Тестирование](#тестирование)

## 📜 Кодекс поведения

Участвуя в проекте, вы соглашаетесь поддерживать дружелюбную и уважительную атмосферу. Мы не терпим:
- Оскорбительные комментарии
- Троллинг или личные атаки
- Публикацию приватной информации
- Неэтичное поведение

## 🤝 Как я могу помочь?

### Сообщить о баге
- Проверьте, что баг еще не зарепорчен в [Issues](https://github.com/yourusername/master-parenthood/issues)
- Создайте issue с детальным описанием:
    - Шаги воспроизведения
    - Ожидаемое поведение
    - Актуальное поведение
    - Скриншоты (если применимо)
    - Версия приложения
    - Устройство и ОС

### Предложить улучшение
- Опишите идею в [Discussions](https://github.com/yourusername/master-parenthood/discussions)
- Объясните, какую проблему это решает
- Предложите возможную реализацию

### Написать код
- Выберите issue с меткой `good first issue` или `help wanted`
- Прокомментируйте, что берете задачу
- Следуйте процессу разработки

## 🔄 Процесс разработки

1. **Fork репозитория**
   ```bash
   git clone https://github.com/yourusername/master-parenthood.git
   cd master-parenthood
   ```

2. **Создайте branch**
   ```bash
   git checkout -b feature/amazing-feature
   # или
   git checkout -b fix/bug-description
   ```

3. **Настройте окружение**
   ```bash
   flutter pub get
   ```

4. **Внесите изменения**
    - Пишите чистый, понятный код
    - Добавляйте комментарии где необходимо
    - Следуйте существующей архитектуре

5. **Протестируйте**
   ```bash
   flutter test
   flutter analyze
   ```

6. **Commit изменения**
   ```bash
   git add .
   git commit -m "feat: add amazing feature"
   ```

7. **Push в ваш fork**
   ```bash
   git push origin feature/amazing-feature
   ```

8. **Создайте Pull Request**

## 💻 Стиль кода

### Dart/Flutter

Мы следуем официальному [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).

Основные правила:
- Используйте `lowerCamelCase` для переменных и функций
- Используйте `UpperCamelCase` для классов
- Максимальная длина строки: 80 символов
- Используйте trailing commas для лучшего форматирования

Пример:
```dart
class ChildProfile {
  final String name;
  final DateTime birthDate;
  
  ChildProfile({
    required this.name,
    required this.birthDate,
  });
  
  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 + 
           now.month - birthDate.month;
  }
}
```

### Структура файлов

```
lib/
├── screens/          # UI экраны
├── widgets/          # Переиспользуемые виджеты
├── services/         # Бизнес-логика
├── models/           # Модели данных
├── providers/        # State management
├── utils/            # Утилиты
└── l10n/            # Локализация
```

### Именование

- **Файлы**: `snake_case.dart`
- **Классы**: `PascalCase`
- **Функции**: `camelCase`
- **Константы**: `SCREAMING_SNAKE_CASE` или `lowerCamelCase`
- **Приватные**: `_privateVariable`

## 📝 Коммиты

Мы используем [Conventional Commits](https://www.conventionalcommits.org/).

### Формат
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Типы
- `feat`: Новая функция
- `fix`: Исправление бага
- `docs`: Изменения в документации
- `style`: Форматирование кода
- `refactor`: Рефакторинг кода
- `perf`: Улучшение производительности
- `test`: Добавление тестов
- `chore`: Обновление зависимостей и т.д.

### Примеры
```bash
feat(auth): add VK authentication
fix(stories): fix story generation for long names
docs(readme): update installation instructions
style: format code with dartfmt
refactor(services): extract AI logic to separate service
```

## 🔍 Pull Requests

### Чеклист для PR

- [ ] Код следует стилю проекта
- [ ] Добавлены/обновлены тесты
- [ ] Документация обновлена
- [ ] Изменения протестированы на Android и iOS
- [ ] Нет конфликтов с main branch
- [ ] PR имеет понятное описание

### Шаблон PR

```markdown
## Описание
Краткое описание изменений

## Тип изменения
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Тестирование
- [ ] Unit tests pass
- [ ] Manual testing completed

## Скриншоты (если применимо)
Добавьте скриншоты UI изменений

## Связанные issues
Closes #123
```

## 🧪 Тестирование

### Unit тесты
```dart
test('ChildProfile calculates age correctly', () {
  final child = ChildProfile(
    name: 'Test',
    birthDate: DateTime(2020, 1, 1),
  );
  
  expect(child.ageInMonths, greaterThan(0));
});
```

### Widget тесты
```dart
testWidgets('HomeScreen shows greeting', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: HomeScreen()),
  );
  
  expect(find.text('Привет!'), findsOneWidget);
});
```

### Запуск тестов
```bash
# Все тесты
flutter test

# С покрытием
flutter test --coverage

# Конкретный файл
flutter test test/services/ai_service_test.dart
```

## 📚 Полезные ресурсы

- [Flutter Documentation](https://flutter.dev/docs)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Firebase Flutter](https://firebase.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)

## ❓ Вопросы?

- Создайте issue с меткой `question`
- Спросите в [Discussions](https://github.com/yourusername/master-parenthood/discussions)
- Напишите на email: dev@masterparenthood.app

---

Спасибо за ваш вклад в Master Parenthood! Вместе м