// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';

// OAuth конфигурация - замените на ваши реальные значения
class OAuthConfig {
  // VK OAuth
  static const String vkAppId = String.fromEnvironment(
    'VK_APP_ID',
    defaultValue: '', // Установите ваш VK App ID
  );
  static const String vkRedirectUri = 'https://oauth.vk.com/blank.html';

  // Яндекс OAuth
  static const String yandexClientId = String.fromEnvironment(
    'YANDEX_CLIENT_ID',
    defaultValue: '', // Установите ваш Yandex Client ID
  );
  static const String yandexRedirectUri = 'https://oauth.yandex.ru/verification_code';
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _backgroundController;
  late AnimationController _socialButtonsController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _socialButtonsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _backgroundController.dispose();
    _socialButtonsController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      _showMessage('Заполните все поля');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await FirebaseService.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        await FirebaseService.registerWithEmail(
          email: email,
          password: password,
          parentName: name,
        );
      }

      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAuthenticated(true);
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await FirebaseService.signInWithGoogle();
      if (user != null && mounted) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAuthenticated(true);
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);

    try {
      final user = await FirebaseService.signInWithFacebook();
      if (user != null && mounted) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAuthenticated(true);
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // VK авторизация через веб
  Future<void> _signInWithVK() async {
    if (OAuthConfig.vkAppId.isEmpty) {
      _showMessage('VK авторизация не настроена');
      if (kDebugMode) {
        debugPrint('⚠️ VK App ID not configured. Set VK_APP_ID environment variable.');
      }
      return;
    }

    final url = Uri.parse('https://oauth.vk.com/authorize'
        '?client_id=${OAuthConfig.vkAppId}'
        '&display=mobile'
        '&redirect_uri=${OAuthConfig.vkRedirectUri}'
        '&scope=email'
        '&response_type=token'
        '&v=5.131');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch VK OAuth');
      }

      _showMessage('Завершите авторизацию в браузере');

      // После авторизации пользователь должен быть перенаправлен обратно в приложение
      // где вы сможете обработать токен через deep links
    } catch (e) {
      _showMessage('Ошибка открытия VK: $e');
    }
  }

  // Яндекс авторизация через веб
  Future<void> _signInWithYandex() async {
    if (OAuthConfig.yandexClientId.isEmpty) {
      _showMessage('Яндекс авторизация не настроена');
      if (kDebugMode) {
        debugPrint('⚠️ Yandex Client ID not configured. Set YANDEX_CLIENT_ID environment variable.');
      }
      return;
    }

    final url = Uri.parse('https://oauth.yandex.ru/authorize'
        '?response_type=token'
        '&client_id=${OAuthConfig.yandexClientId}'
        '&redirect_uri=${OAuthConfig.yandexRedirectUri}');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch Yandex OAuth');
      }

      _showMessage('Завершите авторизацию в браузере');
    } catch (e) {
      _showMessage('Ошибка открытия Яндекс: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Анимированный градиентный фон
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.sin(_backgroundController.value * 2 * math.pi),
                      math.cos(_backgroundController.value * 2 * math.pi),
                    ),
                    end: Alignment(
                      -math.sin(_backgroundController.value * 2 * math.pi),
                      -math.cos(_backgroundController.value * 2 * math.pi),
                    ),
                    colors: [
                      Colors.purple.shade400,
                      Colors.pink.shade400,
                      Colors.blue.shade400,
                    ],
                  ),
                ),
              );
            },
          ),

          // Основной контент
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Логотип приложения
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.child_care,
                          size: 60,
                          color: Colors.purple,
                        ),
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack)
                        .fadeIn(),

                    const SizedBox(height: 20),

                    // Название приложения
                    Text(
                      'Master Parenthood',
                      style:
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),

                    const SizedBox(height: 40),

                    // Форма авторизации
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Заголовок формы
                          Text(
                            _isLogin ? 'С возвращением!' : 'Добро пожаловать!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin
                                ? 'Войдите в свой аккаунт'
                                : 'Создайте новый аккаунт',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Поля ввода
                          if (!_isLogin) ...[
                            _buildTextField(
                              controller: _nameController,
                              label: 'Ваше имя',
                              icon: Icons.person,
                            ).animate().fadeIn().slideY(begin: 0.1),
                            const SizedBox(height: 16),
                          ],

                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _passwordController,
                            label: 'Пароль',
                            icon: Icons.lock,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),

                          if (_isLogin) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showResetPasswordDialog(),
                                child: const Text('Забыли пароль?'),
                              ),
                            ),
                          ],

                          const SizedBox(height: 30),

                          // Кнопка входа/регистрации
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed:
                              _isLoading ? null : _submitEmailPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(
                                _isLogin ? 'Войти' : 'Создать аккаунт',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Разделитель
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'или',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Кнопки социальных сетей
                          _buildSocialButtons(),

                          const SizedBox(height: 20),

                          // Переключение вход/регистрация
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin
                                    ? 'Нет аккаунта?'
                                    : 'Уже есть аккаунт?',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(
                                  _isLogin ? 'Зарегистрируйтесь' : 'Войдите',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        // Google
        _buildSocialButton(
          onPressed: _signInWithGoogle,
          color: Colors.white,
          borderColor: Colors.grey.shade300,
          icon: Icons.g_mobiledata,
          text: 'Войти через Google',
          textColor: Colors.black87,
          delay: 0,
        ),

        const SizedBox(height: 12),

        // Facebook
        _buildSocialButton(
          onPressed: _signInWithFacebook,
          color: const Color(0xFF1877F2),
          icon: Icons.facebook,
          text: 'Войти через Facebook',
          delay: 100,
        ),

        const SizedBox(height: 12),

        // VK
        _buildSocialButton(
          onPressed: _signInWithVK,
          color: const Color(0xFF0077FF),
          icon: Icons.public,
          text: 'Войти через VK',
          delay: 200,
          isAvailable: OAuthConfig.vkAppId.isNotEmpty,
        ),

        const SizedBox(height: 12),

        // Яндекс
        _buildSocialButton(
          onPressed: _signInWithYandex,
          color: const Color(0xFFFC3F1D),
          icon: Icons.language,
          text: 'Войти через Яндекс',
          delay: 300,
          isAvailable: OAuthConfig.yandexClientId.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required Color color,
    Color? borderColor,
    required IconData icon,
    required String text,
    Color textColor = Colors.white,
    required int delay,
    bool isAvailable = true,
  }) {
    return AnimatedBuilder(
      animation: _socialButtonsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            30 * (1 - _socialButtonsController.value),
          ),
          child: Opacity(
            opacity: _socialButtonsController.value,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: (_isLoading || !isAvailable) ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: isAvailable ? color : Colors.grey.shade300,
            side: BorderSide(color: borderColor ?? color),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isAvailable ? textColor : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  color: isAvailable ? textColor : Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!isAvailable && kDebugMode) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (400 + delay).ms).slideX(begin: -0.2);
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс пароля'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Введите email для получения ссылки на сброс пароля',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                _showMessage('Введите email');
                return;
              }

              try {
                await FirebaseService.resetPassword(email);
                if (context.mounted) {
                  Navigator.pop(context);
                  _showMessage('Письмо для сброса пароля отправлено');
                }
              } catch (e) {
                _showMessage(e.toString());
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}