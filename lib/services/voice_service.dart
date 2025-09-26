// lib/services/voice_service.dart
// 🎙️ Advanced Voice Service - Speech Control & Voice Notes
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/injection_container.dart';
import 'cache_service.dart';

class VoiceService {
  static final SpeechToText _speechToText = SpeechToText();
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _speechInitialized = false;
  static bool _ttsInitialized = false;
  static bool _isListening = false;
  static bool _isSpeaking = false;

  // Voice command patterns
  static final Map<String, List<String>> _voiceCommands = {
    'navigate_home': ['go home', 'home screen', 'домой', 'главная'],
    'navigate_diary': ['open diary', 'diary', 'дневник', 'открой дневник'],
    'navigate_feeding': ['feeding', 'food', 'кормление', 'еда'],
    'navigate_sleep': ['sleep', 'bedtime', 'сон', 'спать'],
    'navigate_development': ['development', 'milestones', 'развитие', 'этапы'],
    'navigate_health': ['health', 'medical', 'здоровье', 'медицина'],
    'navigate_community': ['community', 'friends', 'сообщество', 'друзья'],
    'start_voice_note': ['record note', 'voice note', 'запись заметки', 'голосовая заметка'],
    'log_feeding': ['log feeding', 'fed baby', 'записать кормление', 'покормил'],
    'log_sleep': ['log sleep', 'baby sleeping', 'записать сон', 'спит'],
    'log_diaper': ['diaper change', 'changed diaper', 'смена подгузника', 'поменял подгузник'],
    'call_emergency': ['emergency', 'help', 'экстренная помощь', 'помощь'],
    'read_story': ['read story', 'tell story', 'читай сказку', 'расскажи сказку'],
    'play_lullaby': ['lullaby', 'sing', 'колыбельная', 'пой'],
  };

  // Available voices by language
  static final Map<String, List<String>> _preferredVoices = {
    'en': ['en-US-language', 'en-GB-language', 'com.apple.ttsbundle.Samantha-compact'],
    'ru': ['ru-RU-language', 'com.apple.ttsbundle.Milena-compact', 'ru-ru-x-ruf-local'],
    'es': ['es-ES-language', 'es-MX-language', 'com.apple.ttsbundle.Monica-compact'],
    'fr': ['fr-FR-language', 'com.apple.ttsbundle.Thomas-compact'],
    'de': ['de-DE-language', 'com.apple.ttsbundle.Anna-compact'],
  };

  /// Initialize voice services
  static Future<void> initialize() async {
    try {
      await _requestPermissions();
      await _initializeSpeechToText();
      await _initializeTextToSpeech();

      debugPrint('🎙️ Voice Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Voice Service initialization error: $e');
    }
  }

  /// Request necessary permissions
  static Future<void> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();

    if (microphoneStatus.isDenied || speechStatus.isDenied) {
      debugPrint('⚠️ Voice permissions denied');
    }
  }

  /// Initialize speech to text
  static Future<void> _initializeSpeechToText() async {
    try {
      _speechInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );

      if (_speechInitialized) {
        debugPrint('✅ Speech-to-Text initialized');
      }
    } catch (e) {
      debugPrint('❌ Speech-to-Text initialization error: $e');
    }
  }

  /// Initialize text to speech
  static Future<void> _initializeTextToSpeech() async {
    try {
      await _flutterTts.setSharedInstance(true);

      // Set default properties
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);

      // Set callbacks
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('🔊 Started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('🔇 Finished speaking');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      // Set language based on user preference
      await _setLanguageFromPreferences();

      _ttsInitialized = true;
      debugPrint('✅ Text-to-Speech initialized');
    } catch (e) {
      debugPrint('❌ Text-to-Speech initialization error: $e');
    }
  }

  /// Set TTS language from user preferences
  static Future<void> _setLanguageFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('languageCode') ?? 'ru';

      await setLanguage(languageCode);
    } catch (e) {
      debugPrint('Error setting TTS language: $e');
    }
  }

  /// Set voice language and optimal voice
  static Future<void> setLanguage(String languageCode) async {
    if (!_ttsInitialized) return;

    try {
      await _flutterTts.setLanguage(languageCode);

      // Try to set the best voice for the language
      final voices = await _flutterTts.getVoices;
      final preferredVoices = _preferredVoices[languageCode] ?? [];

      for (final preferredVoice in preferredVoices) {
        final voice = voices?.firstWhere(
          (v) => v['name'].toString().contains(preferredVoice),
          orElse: () => null,
        );

        if (voice != null) {
          await _flutterTts.setVoice(voice);
          debugPrint('🗣️ Set voice: ${voice['name']}');
          break;
        }
      }
    } catch (e) {
      debugPrint('Error setting voice language: $e');
    }
  }

  /// Start listening for voice commands
  static Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
    String? language,
  }) async {
    if (!_speechInitialized || _isListening) return;

    try {
      final selectedLanguage = language ?? await _getPreferredLanguage();

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _isListening = false;
            onResult(result.recognizedWords);
            _processVoiceCommand(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: _getLocaleId(selectedLanguage),
        onSoundLevelChange: (level) {
          // Handle sound level changes for visual feedback
        },
        cancelOnError: true,
      );

      _isListening = true;
      debugPrint('🎙️ Started listening for voice commands');
    } catch (e) {
      debugPrint('Error starting voice recognition: $e');
      onError?.call(e.toString());
    }
  }

  /// Stop listening
  static Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      debugPrint('🔇 Stopped listening');
    }
  }

  /// Record voice note
  static Future<String?> recordVoiceNote({
    required String noteId,
    int maxDurationSeconds = 120,
    String? language,
  }) async {
    if (!_speechInitialized) return null;

    try {
      final completer = Completer<String?>();
      String transcribedText = '';

      await _speechToText.listen(
        onResult: (result) {
          transcribedText = result.recognizedWords;
          if (result.finalResult) {
            completer.complete(transcribedText);
          }
        },
        listenFor: Duration(seconds: maxDurationSeconds),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        localeId: _getLocaleId(language ?? await _getPreferredLanguage()),
        cancelOnError: true,
      );

      // Save voice note
      final voiceNoteData = {
        'id': noteId,
        'text': await completer.future,
        'timestamp': DateTime.now().toIso8601String(),
        'duration': maxDurationSeconds,
        'language': language ?? await _getPreferredLanguage(),
      };

      await _saveVoiceNote(voiceNoteData);

      debugPrint('🎙️ Voice note recorded: $noteId');
      return voiceNoteData['text'];
    } catch (e) {
      debugPrint('Error recording voice note: $e');
      return null;
    }
  }

  /// Speak text with enhanced options
  static Future<void> speak({
    required String text,
    String? language,
    double? rate,
    double? pitch,
    double? volume,
    bool interrupt = true,
  }) async {
    if (!_ttsInitialized) return;

    try {
      if (interrupt && _isSpeaking) {
        await stop();
      }

      // Set temporary properties if provided
      if (language != null) await _flutterTts.setLanguage(language);
      if (rate != null) await _flutterTts.setSpeechRate(rate);
      if (pitch != null) await _flutterTts.setPitch(pitch);
      if (volume != null) await _flutterTts.setVolume(volume);

      await _flutterTts.speak(text);
      debugPrint('🔊 Speaking: ${text.substring(0, 50)}${text.length > 50 ? '...' : ''}');
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  /// Speak personalized message for child
  static Future<void> speakForChild({
    required String message,
    required String childName,
    required int ageInMonths,
    String? language,
  }) async {
    final personalizedMessage = _personalizeMessageForChild(message, childName, ageInMonths);

    // Use child-friendly voice settings
    await speak(
      text: personalizedMessage,
      language: language,
      rate: 0.4, // Slower for children
      pitch: 1.2, // Higher pitch for children
      volume: 0.7,
    );
  }

  /// Read story aloud
  static Future<void> readStory({
    required String storyText,
    required String childName,
    String? language,
    Function(String)? onSentenceComplete,
  }) async {
    final sentences = _splitIntoSentences(storyText);

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].replaceAll('{childName}', childName);

      await speak(
        text: sentence,
        language: language,
        rate: 0.45, // Story reading pace
        pitch: 1.1,
        volume: 0.8,
      );

      onSentenceComplete?.call(sentence);

      // Wait for sentence to complete before next one
      while (_isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Pause between sentences
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Play lullaby with voice
  static Future<void> playVoiceLullaby({
    required String childName,
    String? language,
  }) async {
    final lullabies = _getLullabies(language ?? await _getPreferredLanguage());
    final selectedLullaby = lullabies[Random().nextInt(lullabies.length)];

    await speak(
      text: selectedLullaby.replaceAll('{childName}', childName),
      language: language,
      rate: 0.3, // Very slow for lullaby
      pitch: 0.9, // Lower pitch for soothing
      volume: 0.6, // Quiet for bedtime
    );
  }

  /// Stop speaking
  static Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
      debugPrint('🔇 Stopped speaking');
    }
  }

  /// Process voice command and execute action
  static Future<void> _processVoiceCommand(String command) async {
    final lowercaseCommand = command.toLowerCase();

    for (final entry in _voiceCommands.entries) {
      final action = entry.key;
      final patterns = entry.value;

      for (final pattern in patterns) {
        if (lowercaseCommand.contains(pattern.toLowerCase())) {
          await _executeVoiceAction(action, command);
          return;
        }
      }
    }

    // If no command found, log for learning
    await _logUnrecognizedCommand(command);
    debugPrint('❓ Unrecognized voice command: $command');
  }

  /// Execute voice action
  static Future<void> _executeVoiceAction(String action, String originalCommand) async {
    debugPrint('🎯 Executing voice action: $action');

    switch (action) {
      case 'navigate_home':
        // Navigate to home screen
        await speak(text: await _getResponseText('navigating_home'));
        break;

      case 'navigate_diary':
        // Navigate to diary
        await speak(text: await _getResponseText('opening_diary'));
        break;

      case 'start_voice_note':
        // Start voice note recording
        await speak(text: await _getResponseText('starting_voice_note'));
        break;

      case 'log_feeding':
        // Log feeding automatically
        await speak(text: await _getResponseText('logging_feeding'));
        await _quickLogFeeding();
        break;

      case 'log_sleep':
        // Log sleep automatically
        await speak(text: await _getResponseText('logging_sleep'));
        await _quickLogSleep();
        break;

      case 'log_diaper':
        // Log diaper change
        await speak(text: await _getResponseText('logging_diaper'));
        await _quickLogDiaper();
        break;

      case 'read_story':
        // Offer to read a story
        await speak(text: await _getResponseText('reading_story'));
        break;

      case 'play_lullaby':
        // Play lullaby
        await speak(text: await _getResponseText('playing_lullaby'));
        // Get child name and play lullaby
        final childName = await _getChildName();
        await playVoiceLullaby(childName: childName);
        break;

      case 'call_emergency':
        // Emergency response
        await speak(text: await _getResponseText('emergency_response'));
        break;

      default:
        debugPrint('Unknown voice action: $action');
    }

    // Track voice command usage
    await _trackVoiceCommandUsage(action);
  }

  /// Get voice note history
  static Future<List<Map<String, dynamic>>> getVoiceNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('voice_notes') ?? '[]';
      final notes = jsonDecode(notesJson) as List<dynamic>;

      return notes.map((note) => Map<String, dynamic>.from(note)).toList();
    } catch (e) {
      debugPrint('Error getting voice notes: $e');
      return [];
    }
  }

  /// Delete voice note
  static Future<void> deleteVoiceNote(String noteId) async {
    try {
      final notes = await getVoiceNotes();
      notes.removeWhere((note) => note['id'] == noteId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_notes', jsonEncode(notes));

      debugPrint('🗑️ Deleted voice note: $noteId');
    } catch (e) {
      debugPrint('Error deleting voice note: $e');
    }
  }

  /// Get voice command statistics
  static Future<Map<String, dynamic>> getVoiceStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('voice_command_stats') ?? '{}';
      return jsonDecode(statsJson);
    } catch (e) {
      return {};
    }
  }

  // Private helper methods
  static Future<void> _saveVoiceNote(Map<String, dynamic> noteData) async {
    try {
      final notes = await getVoiceNotes();
      notes.insert(0, noteData); // Add to beginning

      // Keep only last 100 notes
      if (notes.length > 100) {
        notes.removeRange(100, notes.length);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_notes', jsonEncode(notes));
    } catch (e) {
      debugPrint('Error saving voice note: $e');
    }
  }

  static String _getLocaleId(String languageCode) {
    switch (languageCode) {
      case 'ru': return 'ru-RU';
      case 'en': return 'en-US';
      case 'es': return 'es-ES';
      case 'fr': return 'fr-FR';
      case 'de': return 'de-DE';
      default: return 'en-US';
    }
  }

  static Future<String> _getPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('languageCode') ?? 'ru';
  }

  static String _personalizeMessageForChild(String message, String childName, int ageInMonths) {
    String personalizedMessage = message.replaceAll('{childName}', childName);

    // Add age-appropriate elements
    if (ageInMonths < 12) {
      personalizedMessage = '👶 $personalizedMessage';
    } else if (ageInMonths < 24) {
      personalizedMessage = '🧸 $personalizedMessage';
    } else {
      personalizedMessage = '🌟 $personalizedMessage';
    }

    return personalizedMessage;
  }

  static List<String> _splitIntoSentences(String text) {
    return text.split(RegExp(r'[.!?]+\s*'))
        .where((sentence) => sentence.trim().isNotEmpty)
        .toList();
  }

  static List<String> _getLullabies(String language) {
    switch (language) {
      case 'ru':
        return [
          'Баю-баюшки-баю, не ложися на краю, {childName}',
          'Спи, {childName}, усни, крепко глазки сомкни',
          'Тишина у пруда, не качается вода, спи {childName}',
        ];
      case 'en':
        return [
          'Rock-a-bye {childName}, in the treetop',
          'Twinkle, twinkle, little star, {childName}',
          'Hush little {childName}, don\'t say a word',
        ];
      default:
        return [
          'Sleep tight, {childName}',
          'Sweet dreams, {childName}',
        ];
    }
  }

  static Future<String> _getResponseText(String key) async {
    final language = await _getPreferredLanguage();

    final responses = {
      'ru': {
        'navigating_home': 'Переходим на главную',
        'opening_diary': 'Открываю дневник',
        'starting_voice_note': 'Начинаю запись заметки',
        'logging_feeding': 'Записываю кормление',
        'logging_sleep': 'Записываю сон',
        'logging_diaper': 'Записываю смену подгузника',
        'reading_story': 'Сейчас прочитаю сказку',
        'playing_lullaby': 'Спою колыбельную',
        'emergency_response': 'Вызываю экстренную помощь',
      },
      'en': {
        'navigating_home': 'Navigating to home',
        'opening_diary': 'Opening diary',
        'starting_voice_note': 'Starting voice note recording',
        'logging_feeding': 'Logging feeding',
        'logging_sleep': 'Logging sleep',
        'logging_diaper': 'Logging diaper change',
        'reading_story': 'I\'ll read you a story',
        'playing_lullaby': 'Playing lullaby',
        'emergency_response': 'Calling emergency services',
      },
    };

    return responses[language]?[key] ?? responses['en']![key]!;
  }

  static Future<String> _getChildName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('child_name') ?? 'малыш';
    } catch (e) {
      return 'малыш';
    }
  }

  static Future<void> _quickLogFeeding() async {
    // Quick feeding log implementation
    try {
      final timestamp = DateTime.now();
      final feedingData = {
        'timestamp': timestamp.toIso8601String(),
        'type': 'breast_milk', // Default
        'duration': 15, // Default 15 minutes
        'voice_logged': true,
      };

      // Save to feeding history
      final prefs = await SharedPreferences.getInstance();
      final feedingsJson = prefs.getString('quick_feedings') ?? '[]';
      final feedings = jsonDecode(feedingsJson) as List<dynamic>;
      feedings.insert(0, feedingData);

      await prefs.setString('quick_feedings', jsonEncode(feedings));
      debugPrint('🍼 Quick feeding logged');
    } catch (e) {
      debugPrint('Error logging quick feeding: $e');
    }
  }

  static Future<void> _quickLogSleep() async {
    // Quick sleep log implementation
    try {
      final timestamp = DateTime.now();
      final sleepData = {
        'start_time': timestamp.toIso8601String(),
        'type': 'nap',
        'voice_logged': true,
      };

      final prefs = await SharedPreferences.getInstance();
      final sleepsJson = prefs.getString('quick_sleeps') ?? '[]';
      final sleeps = jsonDecode(sleepsJson) as List<dynamic>;
      sleeps.insert(0, sleepData);

      await prefs.setString('quick_sleeps', jsonEncode(sleeps));
      debugPrint('😴 Quick sleep logged');
    } catch (e) {
      debugPrint('Error logging quick sleep: $e');
    }
  }

  static Future<void> _quickLogDiaper() async {
    // Quick diaper change log implementation
    try {
      final timestamp = DateTime.now();
      final diaperData = {
        'timestamp': timestamp.toIso8601String(),
        'type': 'wet', // Default
        'voice_logged': true,
      };

      final prefs = await SharedPreferences.getInstance();
      final diapersJson = prefs.getString('quick_diapers') ?? '[]';
      final diapers = jsonDecode(diapersJson) as List<dynamic>;
      diapers.insert(0, diaperData);

      await prefs.setString('quick_diapers', jsonEncode(diapers));
      debugPrint('👶 Quick diaper change logged');
    } catch (e) {
      debugPrint('Error logging quick diaper change: $e');
    }
  }

  static Future<void> _logUnrecognizedCommand(String command) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unrecognizedJson = prefs.getString('unrecognized_commands') ?? '[]';
      final unrecognized = jsonDecode(unrecognizedJson) as List<dynamic>;

      unrecognized.insert(0, {
        'command': command,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Keep only last 50
      if (unrecognized.length > 50) {
        unrecognized.removeRange(50, unrecognized.length);
      }

      await prefs.setString('unrecognized_commands', jsonEncode(unrecognized));
    } catch (e) {
      debugPrint('Error logging unrecognized command: $e');
    }
  }

  static Future<void> _trackVoiceCommandUsage(String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('voice_command_stats') ?? '{}';
      final stats = jsonDecode(statsJson) as Map<String, dynamic>;

      stats[action] = (stats[action] as int? ?? 0) + 1;
      await prefs.setString('voice_command_stats', jsonEncode(stats));
    } catch (e) {
      debugPrint('Error tracking voice command usage: $e');
    }
  }

  /// Check if voice services are available
  static bool get isListening => _isListening;
  static bool get isSpeaking => _isSpeaking;
  static bool get speechAvailable => _speechInitialized;
  static bool get ttsAvailable => _ttsInitialized;

  /// Dispose voice services
  static Future<void> dispose() async {
    await stopListening();
    await stop();
    debugPrint('🎙️ Voice Service disposed');
  }
}