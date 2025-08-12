import 'package:live_voice_translator/models/language.dart';

class SpeechService {
  bool _isListening = false;

  // Callback functions
  Function(String)? _onResult;
  Function(String)? _onError;

  Future<bool> initialize() async {
    // In this build, real speech recognition is not enabled.
    // We explicitly avoid any demo text generation.
    return true;
  }

  Future<void> startListening({
    required Language language,
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    _onResult = onResult;
    _onError = onError;
    _isListening = true;

    await initialize();

    // Notify user that we are ready, without generating any text.
    _onError?.call('Listening in ${language.nativeName}. Use the yellow button to mark phrase boundaries or the keyboard icon to type.');
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  void interruptPhrase() {
    // Do not generate text; simply inform about phrase separation.
    _onError?.call('Phrase boundary set');
  }

  bool get isListening => _isListening;
  bool get isAvailable => true;

  void dispose() {
    stopListening();
  }
}