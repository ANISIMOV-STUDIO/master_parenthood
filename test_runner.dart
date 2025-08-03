// test_runner.dart
// Простой скрипт для запуска различных типов тестов

import 'dart:io';

void main(List<String> arguments) {
  print('🧪 Master Parenthood Test Runner');
  print('================================');

  if (arguments.isEmpty) {
    print('Usage: dart test_runner.dart [unit|widget|integration|all]');
    exit(1);
  }

  final testType = arguments[0].toLowerCase();

  switch (testType) {
    case 'unit':
      runUnitTests();
      break;
    case 'widget':
      runWidgetTests();
      break;
    case 'integration':
      runIntegrationTests();
      break;
    case 'all':
      runAllTests();
      break;
    default:
      print('Unknown test type: $testType');
      print('Available types: unit, widget, integration, all');
      exit(1);
  }
}

void runUnitTests() {
  print('🔬 Running Unit Tests...');
  final result = Process.runSync(
    'flutter',
    ['test', 'test/services/'],
    runInShell: true,
  );
  
  print(result.stdout);
  if (result.stderr.toString().isNotEmpty) {
    print('Errors:');
    print(result.stderr);
  }
  
  if (result.exitCode == 0) {
    print('✅ Unit tests passed!');
  } else {
    print('❌ Unit tests failed!');
    exit(result.exitCode);
  }
}

void runWidgetTests() {
  print('🎨 Running Widget Tests...');
  final result = Process.runSync(
    'flutter',
    ['test', 'test/widgets/'],
    runInShell: true,
  );
  
  print(result.stdout);
  if (result.stderr.toString().isNotEmpty) {
    print('Errors:');
    print(result.stderr);
  }
  
  if (result.exitCode == 0) {
    print('✅ Widget tests passed!');
  } else {
    print('❌ Widget tests failed!');
    exit(result.exitCode);
  }
}

void runIntegrationTests() {
  print('🚀 Running Integration Tests...');
  print('Note: Make sure you have a connected device or emulator');
  
  final result = Process.runSync(
    'flutter',
    ['test', 'test/integration/', '--device-id=chrome'],
    runInShell: true,
  );
  
  print(result.stdout);
  if (result.stderr.toString().isNotEmpty) {
    print('Errors:');
    print(result.stderr);
  }
  
  if (result.exitCode == 0) {
    print('✅ Integration tests passed!');
  } else {
    print('❌ Integration tests failed!');
    exit(result.exitCode);
  }
}

void runAllTests() {
  print('🧪 Running All Tests...');
  print('');
  
  try {
    runUnitTests();
    print('');
    runWidgetTests();
    print('');
    runIntegrationTests();
    print('');
    print('🎉 All tests completed successfully!');
  } catch (e) {
    print('💥 Test suite failed: $e');
    exit(1);
  }
}