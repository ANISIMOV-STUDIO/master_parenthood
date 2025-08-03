// test/widgets/sync_status_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_parenthood/widgets/sync_status_widget.dart';

void main() {
  group('SyncStatusWidget', () {
    testWidgets('should not display when no unsynced data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusWidget(),
          ),
        ),
      );

      // Виджет не должен отображаться если нет несинхронизированных данных
      expect(find.byType(SyncStatusWidget), findsOneWidget);
      
      // Но содержимое должно быть пустым (SizedBox.shrink)
      expect(find.text('Есть несинхронизированные данные'), findsNothing);
    });

    testWidgets('should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusWidget(),
          ),
        ),
      );

      // Проверяем, что виджет построился без ошибок
      expect(tester.takeException(), isNull);
    });

    testWidgets('should have correct widget hierarchy', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusWidget(),
          ),
        ),
      );

      // Проверяем основную структуру виджета
      expect(find.byType(SyncStatusWidget), findsOneWidget);
    });

    testWidgets('should be responsive to theme changes', (WidgetTester tester) async {
      // Тест с светлой темой
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: SyncStatusWidget(),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);

      // Тест с темной темой
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SyncStatusWidget(),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}