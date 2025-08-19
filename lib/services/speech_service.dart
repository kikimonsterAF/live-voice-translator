import 'dart:async';
import 'package:live_voice_translator/models/language.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  bool _isListening = false;
  late stt.SpeechToText _speech;
  Timer? _restartTimer;
  Language? _currentLanguage;

  // Callback functions
  Function(String)? _onResult;
  Function(String)? _onError;

  Future<bool> initialize() async {
    try {
      _speech = stt.SpeechToText();
      return await _speech.initialize(
        onError: (error) {
          final msg = (error.errorMsg ?? '').toLowerCase();
          final isTransient = !(error.permanent == true);
          if (isTransient && _isNoInputError(msg)) {
            // Benign: no recognized speech in window → keep going
            _scheduleRestart();
            return;
          }
          _onError?.call('Speech error: ${error.errorMsg}');
        },
      );
    } catch (e) {
      _onError?.call('Failed to initialize speech: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Language language,
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    _onResult = onResult;
    _onError = onError;
    _currentLanguage = language;
    _isListening = true;

    try {
      final initialized = await initialize();
      if (!initialized) {
        _onError?.call('Speech recognition not available');
        return;
      }

      await _startListeningSession(language);
    } catch (e) {
      _onError?.call('Could not start speech: $e');
    }
  }

  bool _isNoInputError(String msg) {
    // Normalize and match common variants from Android/iOS engines
    // e.g., "no match", "error_no_match", "no-speech", "no speech"
    return msg.contains('no match') ||
        msg.contains('nomatch') ||
        msg.contains('no-speech') ||
        msg.contains('no speech') ||
        msg.contains('no input') ||
        msg.contains('not recognized') ||
        msg.contains('nothing to recognize');
  }

  Future<void> _startListeningSession(Language language) async {
    if (!_isListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _onResult?.call(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: null,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        localeId: language.localeCode,
      );
    } catch (e) {
      if (_isListening) {
        print('Listening session ended, restarting...');
        _scheduleRestart();
      }
    }
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 1), () {
      if (_isListening) {
        _startListeningSession(_getCurrentLanguage());
      }
    });
  }

  Language _getCurrentLanguage() {
    return _currentLanguage ?? SupportedLanguages.defaultInputLanguage;
  }

  Future<void> stopListening() async {
    _isListening = false;
    _restartTimer?.cancel();
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {
      // no-op
    }
  }

  void interruptPhrase() {
    if (_isListening) {
      _onResult?.call('[Phrase Break]');
    }
  }

  // Remove old platform channel code - no longer needed

  bool get isListening => _isListening;
  bool get isAvailable => true;

  void dispose() {
    _restartTimer?.cancel();
    stopListening();
  }
}