import 'package:flutter/material.dart';
import 'dart:async';
import 'package:live_voice_translator/models/language.dart';
import 'package:live_voice_translator/services/speech_service.dart';
import 'package:live_voice_translator/services/translation_service.dart';

class TranslationProvider extends ChangeNotifier {
  Language _inputLanguage = SupportedLanguages.defaultInputLanguage;
  Language _outputLanguage = SupportedLanguages.defaultOutputLanguage;
  
  String _originalText = '';
  String _translatedText = '';
  bool _isListening = false;
  bool _isTranslating = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  DateTime _lastTranslationAt = DateTime.fromMillisecondsSinceEpoch(0);

  final SpeechService _speechService = SpeechService();
  final TranslationService _translationService = TranslationService();

  // Getters
  Language get inputLanguage => _inputLanguage;
  Language get outputLanguage => _outputLanguage;
  String get originalText => _originalText;
  String get translatedText => _translatedText;
  bool get isListening => _isListening;
  bool get isTranslating => _isTranslating;
  String get errorMessage => _errorMessage;

  // Setters
  void setInputLanguage(Language language) {
    _inputLanguage = language;
    notifyListeners();
  }

  void setOutputLanguage(Language language) {
    _outputLanguage = language;
    notifyListeners();
  }

  void setOriginalText(String text) {
    _originalText = text;
    notifyListeners();
  }

  void setTranslatedText(String text) {
    _translatedText = text;
    notifyListeners();
  }

  void setListening(bool listening) {
    _isListening = listening;
    notifyListeners();
  }

  void setTranslating(bool translating) {
    _isTranslating = translating;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void clearTexts() {
    _originalText = '';
    _translatedText = '';
    notifyListeners();
  }

  Future<void> startListening() async {
    try {
      clearError();
      setListening(true);
      
      await _speechService.startListening(
        language: _inputLanguage,
        onResult: (text) async {
          setOriginalText(text);
          // Debounce translations to feel more streaming and reduce API chatter
          _debounceTimer?.cancel();
          if (text.trim().length < 3) return;

          const debounceMs = 600;
          const minIntervalMs = 900;

          final now = DateTime.now();
          final elapsed = now.difference(_lastTranslationAt).inMilliseconds;

          if (elapsed >= minIntervalMs) {
            _lastTranslationAt = now;
            unawaited(translateText(text));
          } else {
            _debounceTimer = Timer(const Duration(milliseconds: debounceMs), () {
              _lastTranslationAt = DateTime.now();
              unawaited(translateText(_originalText));
            });
          }
        },
        onError: (error) {
          setError(error);
          setListening(false);
        },
      );
    } catch (e) {
      setError('Failed to start listening: $e');
      setListening(false);
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechService.stopListening();
      setListening(false);
    } catch (e) {
      setError('Failed to stop listening: $e');
      setListening(false);
    }
  }

  Future<void> translateText(String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      setTranslating(true);
      clearError();
      
      final translation = await _translationService.translate(
        text: text,
        from: _inputLanguage.code,
        to: _outputLanguage.code,
      );
      
      setTranslatedText(translation);
    } catch (e) {
      setError('Translation failed: $e');
    } finally {
      setTranslating(false);
    }
  }

  void interruptPhrase() {
    // Force processing of current buffer and start new phrase
    _speechService.interruptPhrase();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _speechService.dispose();
    super.dispose();
  }
}
