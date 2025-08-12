import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle, EventChannel, MethodChannel;
import 'package:google_speech/google_speech.dart';

class GcpSttService {
  // Native PCM mic stream
  static const _audioChannel = EventChannel('flutter.native/audioStream');
  static const _method = MethodChannel('flutter.native/speech');
  StreamSubscription<dynamic>? _responseSub;
  StreamSubscription<dynamic>? _pcmSubscription;
  bool _isRecording = false;

  Future<ServiceAccount> _loadServiceAccount() async {
    final jsonStr = await rootBundle.loadString('assets/secrets/gcp_service_account.json');
    return ServiceAccount.fromString(jsonStr);
  }

  Future<void> start({
    required String locale,
    required void Function(String text, bool isFinal) onTranscript,
    required void Function(String error) onError,
  }) async {
    if (_isRecording) return;
    _isRecording = true;

    try {
      final serviceAccount = await _loadServiceAccount();
      final speechToText = SpeechToText.viaServiceAccount(serviceAccount);

      final config = RecognitionConfig(
        encoding: AudioEncoding.LINEAR16,
        sampleRateHertz: 16000,
        languageCode: locale,
        enableAutomaticPunctuation: true,
        model: RecognitionModel.command_and_search,
        useEnhanced: true,
      );

      final streamingConfig = StreamingRecognitionConfig(
        config: config,
        interimResults: true,
        singleUtterance: false,
      );

      // Start native PCM capture
      await _method.invokeMethod('startPcm');

      final pcmStream = _audioChannel
          .receiveBroadcastStream()
          .map((buffer) => (buffer as Uint8List).toList());
      final responses = speechToText.streamingRecognize(streamingConfig, pcmStream);

      _responseSub = responses.listen((data) {
        final dyn = data as dynamic;
        final results = dyn.results as List?;
        if (results != null && results.isNotEmpty) {
          final result = results.first;
          final alts = (result.alternatives as List?) ?? const [];
          if (alts.isNotEmpty) {
            final transcript = (alts.first.transcript as String?) ?? '';
            final isFinal = (result.isFinal as bool?) ?? false;
            if (transcript.isNotEmpty) {
              onTranscript(transcript, isFinal);
            }
          }
        }
      }, onError: (e) {
        onError(e.toString());
        stop();
      }, onDone: () {
        // auto-restart if still recording
        if (_isRecording) {
          stop();
          start(locale: locale, onTranscript: onTranscript, onError: onError);
        }
      });

      _pcmSubscription = pcmStream.listen((_) {});
    } catch (e) {
      onError('GCP STT start failed: $e');
      _isRecording = false;
    }
  }

  Future<void> stop() async {
    if (!_isRecording) return;
    _isRecording = false;
    try {
      await _method.invokeMethod('stopPcm');
    } catch (_) {}
    await _pcmSubscription?.cancel();
    await _responseSub?.cancel();
    _responseSub = null;
  }
}


