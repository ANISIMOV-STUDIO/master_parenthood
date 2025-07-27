// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

// Провайдеры
import 'providers/locale_provider.dart';

// Экраны
import 'screens/home_screen.dart';
import 'screens/child_profile_screen.dart';

// Локализация
import 'l10n/app_localizations.dart';

// Сервисы
import 'services/mock_firebase_service.dart' as mock_firebase;
import 'services/platform_firebase_service.dart' as platform_firebase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase (отключено для всех платформ)
  // if (!kIsWeb) {
  //   try {
  //     await Firebase.initializeApp();
  //   } catch (e) {
  //     print('Firebase initialization failed: $e');
  //     // Продолжаем без Firebase
  //   }
  // }

  // Загружаем сохраненные настройки
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final languageCode = prefs.getString('languageCode') ?? 'ru';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(isDarkMode),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(Locale(languageCode)),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// Функция для определения авторизации
bool _isAuthenticated() {
  // Используем мок-сервис для всех платформ
  return mock_firebase.MockFirebaseService.isAuthenticated;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Master Parenthood',
      debugShowCheckedModeBanner: false,

      // Темы
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Локализация
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'), // Русский
        Locale('en'), // English
        Locale('es'), // Español
        Locale('fr'), // Français
        Locale('de'), // Deutsch
      ],

      // Проверка авторизации
      home: _isAuthenticated() 
          ? const MainScreen() 
          : const AuthScreen(),
    );
  }
}

// Провайдер темы
class ThemeProvider extends ChangeNotifier {
  bool isDarkMode;

  ThemeProvider(this.isDarkMode);

  void toggleTheme() async {
    isDarkMode = !isDarkMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }
}

// Главный экран с навигацией
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChildProfileScreen(),
    const AchievementsScreen(),
    const CommunityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home),
            label: loc.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.child_care),
            label: loc.child,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events),
            label: loc.achievements,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups),
            label: loc.community,
          ),
        ],
      ),
    );
  }
}

// Экран загрузки
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade400,
              Colors.pink.shade400,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.child_care,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Master Parenthood',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Экран авторизации (базовый)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await mock_firebase.MockFirebaseService.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        await mock_firebase.MockFirebaseService.registerWithEmail(
          email: email,
          password: password,
          parentName: 'Родитель',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // Обновляем состояние приложения после авторизации
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade300,
              Colors.pink.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.child_care,
                        size: 60,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isLogin ? 'Вход' : 'Регистрация',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                            _isLogin ? 'Войти' : 'Зарегистрироваться',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? 'Создать аккаунт' : 'Уже есть аккаунт?',
                          style: const TextStyle(color: Colors.purple),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Заглушки для экранов
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Достижения'),
      ),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Сообщество'),
      ),
    );
  }
}