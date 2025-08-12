import 'package:live_voice_translator/models/language.dart';

class SpeechService {
  bool _isListening = false;
  
  // Callback functions
  Function(String)? _onResult;
  Function(String)? _onError;

  // Demo phrases for testing
  final List<String> _demoPhrases = [
    'Hello, how are you?',
    'Good morning',
    'Thank you very much',
    'Where is the bathroom?',
    'How much does this cost?',
    'Can you help me?',
    'I would like to order food',
    'What time is it?',
    'Nice to meet you',
    'Have a good day',
  ];

  int _currentPhraseIndex = 0;

  Future<bool> initialize() async {
    // For demo purposes, always return true
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

    try {
      // Simulate speech recognition with demo phrases
      _simulateSpeechInput();
    } catch (e) {
      _onError?.call('Failed to start listening: $e');
    }
  }

  void _simulateSpeechInput() {
    // Simulate speech input every 3 seconds with demo phrases
    Future.delayed(const Duration(seconds: 2), () {
      if (_isListening && _onResult != null) {
        final phrase = _demoPhrases[_currentPhraseIndex];
        _currentPhraseIndex = (_currentPhraseIndex + 1) % _demoPhrases.length;
        _onResult!(phrase);
        
        // Continue simulating if still listening
        if (_isListening) {
          _simulateSpeechInput();
        }
      }
    });
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  void interruptPhrase() {
    // For demo, just trigger the next phrase immediately
    if (_isListening && _onResult != null) {
      final phrase = _demoPhrases[_currentPhraseIndex];
      _currentPhraseIndex = (_currentPhraseIndex + 1) % _demoPhrases.length;
      _onResult!(phrase);
    }
  }

  bool get isListening => _isListening;
  bool get isAvailable => true; // Always available for demo

  void dispose() {
    stopListening();
  }
}