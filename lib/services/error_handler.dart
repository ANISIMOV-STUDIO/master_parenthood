// lib/services/error_handler.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    } else if (error is FirebaseException) {
      return _handleFirebaseError(error);
    } else if (error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup')) {
      return 'Нет подключения к интернету. Проверьте соединение.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Превышено время ожидания. Попробуйте еще раз.';
    } else if (error.toString().contains('Connection refused')) {
      return 'Не удалось подключиться к серверу. Попробуйте позже.';
    } else if (error.toString().contains('Invalid API key')) {
      return 'Проблема с конфигурацией. Обратитесь в поддержку.';
    } else if (error.toString().contains('Rate limit')) {
      return 'Слишком много запросов. Подождите немного.';
    } else if (error.toString().contains('File size exceeds')) {
      return 'Файл слишком большой. Максимальный размер: 5 МБ.';
    }
    
    // Убираем технические детали из сообщения
    final message = error.toString().replaceAll('Exception: ', '');
    if (message.length > 100) {
      return 'Произошла ошибка. Попробуйте еще раз.';
    }
    
    return message;
  }
  
  static String _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'weak-password':
        return 'Слишком слабый пароль. Используйте минимум 6 символов.';
      case 'email-already-in-use':
        return 'Этот email уже используется другим аккаунтом.';
      case 'invalid-email':
        return 'Неверный формат email адреса.';
      case 'user-not-found':
        return 'Пользователь с таким email не найден.';
      case 'wrong-password':
        return 'Неверный пароль. Попробуйте еще раз.';
      case 'user-disabled':
        return 'Этот аккаунт был заблокирован.';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже.';
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение к интернету.';
      default:
        return 'Ошибка авторизации: ${error.message}';
    }
  }
  
  static String _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'unavailable':
        return 'Сервис временно недоступен. Попробуйте позже.';
      case 'permission-denied':
        return 'У вас нет прав для выполнения этого действия.';
      case 'not-found':
        return 'Запрашиваемые данные не найдены.';
      default:
        return 'Ошибка сервиса: ${error.message}';
    }
  }
  
  static void showErrorDialog(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    final isNetworkError = message.contains('интернет') || 
                          message.contains('сеть') || 
                          message.contains('подключ');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isNetworkError ? Icons.wifi_off : Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Ошибка'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
  
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}