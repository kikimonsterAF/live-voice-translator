import 'dart:async';
import 'package:flutter/services.dart';
import 'package:live_voice_translator/models/language.dart';

class SpeechService {
  bool _isListening = false;
  static const platform = MethodChannel('flutter.native/speech');
  String _pendingLocale = 'en-US';

  // Callback functions
  Function(String)? _onResult;
  Function(String)? _onError;

  SpeechService() {
    platform.setMethodCallHandler(_handlePlatformCallback);
  }

  Future<bool> initialize() async {
    try {
      final granted = await platform.invokeMethod<bool>('requestPermission');
      return granted == true;
    } catch (_) {
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
    _isListening = true;

    _pendingLocale = _toLocale(language.code);
    // Fire permission request, and attempt to start; native side will prompt if needed
    unawaited(initialize());
    try {
      await platform.invokeMethod('startListening', {
        'language': _pendingLocale,
      });
    } catch (e) {
      _onError?.call('Could not start speech: $e');
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    try {
      await platform.invokeMethod('stopListening');
    } catch (_) {
      // no-op
    }
  }

  void interruptPhrase() {
    if (_isListening) {
      _onResult?.call('[Phrase Break]');
    }
  }

  String _toLocale(String code) {
    switch (code) {
      case 'en':
        return 'en-US';
      case 'zh':
        return 'zh-CN';
      case 'hi':
        return 'hi-IN';
      case 'es':
        return 'es-ES';
      case 'ar':
        return 'ar-SA';
      case 'bn':
        return 'bn-BD';
      case 'fr':
        return 'fr-FR';
      case 'ru':
        return 'ru-RU';
      case 'pt':
        return 'pt-BR';
      case 'ur':
        return 'ur-PK';
      case 'vi':
        return 'vi-VN';
      default:
        return 'en-US';
    }
  }

  Future<dynamic> _handlePlatformCallback(MethodCall call) async {
    switch (call.method) {
      case 'onPermissionResult':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final granted = args['granted'] == true;
        if (granted && _isListening) {
          try {
            await platform.invokeMethod('startListening', {
              'language': _pendingLocale,
            });
          } catch (e) {
            _onError?.call('Failed to start speech: $e');
          }
        } else if (!granted) {
          _onError?.call('Microphone permission denied. Enable it in Settings.');
          _isListening = false;
        }
        break;
      case 'onSpeechResult':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final text = (args['text'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          _onResult?.call(text);
        }
        break;
      case 'onSpeechError':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final error = args['error'] as String? ?? 'Unknown error';
        _onError?.call('Speech error: $error');
        break;
    }
    return null;
  }

  bool get isListening => _isListening;
  bool get isAvailable => true;

  void dispose() {
    stopListening();
  }
}