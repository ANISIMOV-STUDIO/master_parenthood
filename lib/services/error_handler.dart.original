// lib/services/error_handler.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Глобальный обработчик ошибок Firebase и сети
class ErrorHandler {
  /// Обработать ошибку Firebase
  static String handleFirebaseError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Нет доступа к данным. Проверьте настройки Firebase.';
        case 'unavailable':
          return 'Сервис временно недоступен. Попробуйте позже.';
        case 'deadline-exceeded':
          return 'Превышено время ожидания. Проверьте интернет-соединение.';
        case 'network-request-failed':
          return 'Ошибка сети. Проверьте интернет-соединение.';
        case 'not-found':
          return 'Данные не найдены.';
        case 'already-exists':
          return 'Данные уже существуют.';
        case 'quota-exceeded':
          return 'Превышен лимит запросов. Попробуйте позже.';
        case 'unauthenticated':
          return 'Требуется авторизация.';
        default:
          return 'Ошибка Firebase: ${error.message ?? 'Неизвестная ошибка'}';
      }
    }
    
    if (error.toString().contains('network')) {
      return 'Проблемы с интернет-соединением';
    }
    
    return 'Произошла ошибка: ${error.toString()}';
  }

  /// Показать ошибку пользователю
  static void showError(BuildContext context, dynamic error, {String? title}) {
    final message = handleFirebaseError(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(message),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Закрыть',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Безопасное выполнение Firebase операции
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    T? fallback,
    String? errorMessage,
  }) async {
    try {
      return await operation();
    } catch (e) {
      debugPrint('Firebase Error: $e');
      if (errorMessage != null) {
        debugPrint('Context: $errorMessage');
      }
      return fallback;
    }
  }

  /// Обработчик для StreamBuilder ошибок
  static Widget buildErrorWidget(dynamic error, {VoidCallback? onRetry}) {
    final message = handleFirebaseError(error);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Проблемы с подключением',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Показать лоадер с возможностью отмены
  static Widget buildLoadingWidget({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}