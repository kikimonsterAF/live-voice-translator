import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:google_speech/google_speech.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class GcpSttService {
  late stt.SpeechToText _speech;
  bool _isRecording = false;
  Timer? _silenceTimer;
  
  // For Google Cloud Speech-to-Text
  ServiceAccount? _serviceAccount;

  Future<ServiceAccount?> _loadServiceAccount() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/secrets/gcp_service_account.json');
      return ServiceAccount.fromString(jsonStr);
    } catch (e) {
      print('Could not load GCP service account: $e');
      return null;
    }
  }

  Future<void> start({
    required String locale,
    required void Function(String text, bool isFinal) onTranscript,
    required void Function(String error) onError,
  }) async {
    if (_isRecording) return;
    _isRecording = true;

    try {
      // Load service account for potential future use
      _serviceAccount = await _loadServiceAccount();
      
      // Initialize speech recognition
      _speech = stt.SpeechToText();
      bool available = await _speech.initialize(
        onError: (error) {
          onError('Speech recognition error: ${error.errorMsg}');
        },
      );

      if (!available) {
        onError('Speech recognition not available');
        _isRecording = false;
        return;
      }

      // Start listening with enhanced configuration
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onTranscript(result.recognizedWords, result.finalResult);
            
            // Reset silence timer on speech
            _silenceTimer?.cancel();
            _silenceTimer = Timer(const Duration(seconds: 3), () {
              if (_isRecording) {
                // Restart listening after silence
                _restartListening(locale, onTranscript, onError);
              }
            });
          }
        },
        listenFor: const Duration(seconds: 30), // Extended listen duration
        pauseFor: const Duration(seconds: 2), // Shorter pause duration
        partialResults: true, // Enable interim results
        onSoundLevelChange: (level) {
          // Optional: could use for visual feedback
        },
        cancelOnError: false,
        listenMode: stt.ListenMode.confirmation,
        localeId: locale,
      );
      
    } catch (e) {
      onError('GCP STT start failed: $e');
      _isRecording = false;
    }
  }

  Future<void> _restartListening(
    String locale,
    void Function(String text, bool isFinal) onTranscript,
    void Function(String error) onError,
  ) async {
    if (!_isRecording) return;
    
    try {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (_isRecording) {
        await _speech.listen(
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty) {
              onTranscript(result.recognizedWords, result.finalResult);
              
              _silenceTimer?.cancel();
              _silenceTimer = Timer(const Duration(seconds: 3), () {
                if (_isRecording) {
                  _restartListening(locale, onTranscript, onError);
                }
              });
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
          localeId: locale,
        );
      }
    } catch (e) {
      onError('Failed to restart listening: $e');
    }
  }

  Future<void> stop() async {
    if (!_isRecording) return;
    _isRecording = false;
    
    try {
      _silenceTimer?.cancel();
      _silenceTimer = null;
      
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }
}


