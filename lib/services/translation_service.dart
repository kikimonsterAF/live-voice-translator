import 'dart:convert';
import 'package:http/http.dart' as http;

// DO NOT COMMIT KEYS. This file reads from a local-only secrets file if present.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class TranslationService {
  // Primary: Google Translate v2 REST API
  static const String _googleUrl = 'https://translation.googleapis.com/language/translate/v2';
  String? _apiKey; // loaded from local secrets
  
  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    try {
      // Clean the input text
      final cleanText = text.trim();
      if (cleanText.isEmpty) {
        return '';
      }

      // If translating to the same language, return original
      if (from == to) {
        return cleanText;
      }

      // Ensure API key
      final key = await _loadApiKey();
      if (key == null || key.isEmpty) {
        throw Exception('Missing Google Translate API key');
      }

      // Google Translate v2 request (simple and low-latency for short segments)
      final url = Uri.parse('$_googleUrl?key=$key');
      final body = {
        'q': cleanText,
        'source': from,
        'target': to,
        'format': 'text',
      };
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final translations = (data['data']?['translations'] as List?) ?? [];
        if (translations.isNotEmpty) {
          final translatedText = translations.first['translatedText'] as String? ?? '';
          return translatedText;
        }
        throw Exception('Unexpected response');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Fallback if API fails
      return _getFallbackTranslation(text, from, to);
    }
  }

  // Fallback translation for demo purposes
  String _getFallbackTranslation(String text, String from, String to) {
    // This is a simple fallback - in production you might cache translations
    // or use offline translation capabilities
    
    final fallbackTranslations = {
      'en_vi': {
        'hello': 'xin chào',
        'goodbye': 'tạm biệt',
        'thank you': 'cảm ơn',
        'yes': 'có',
        'no': 'không',
        'please': 'xin hãy',
        'excuse me': 'xin lỗi',
        'how are you': 'bạn có khỏe không',
        'good morning': 'chào buổi sáng',
        'good evening': 'chào buổi tối',
      },
      'vi_en': {
        'xin chào': 'hello',
        'tạm biệt': 'goodbye',
        'cảm ơn': 'thank you',
        'có': 'yes',
        'không': 'no',
        'xin hãy': 'please',
        'xin lỗi': 'excuse me',
        'bạn có khỏe không': 'how are you',
        'chào buổi sáng': 'good morning',
        'chào buổi tối': 'good evening',
      },
    };

    final key = '${from}_$to';
    final translations = fallbackTranslations[key];
    
    if (translations != null) {
      final lowerText = text.toLowerCase();
      for (final entry in translations.entries) {
        if (lowerText.contains(entry.key)) {
          return lowerText.replaceAll(entry.key, entry.value);
        }
      }
    }

    // If no fallback found, return original with a note
    return '$text (Translation unavailable)';
  }

  // Method to check if translation service is available
  Future<bool> isServiceAvailable() async {
    try {
      final key = await _loadApiKey();
      if (key == null || key.isEmpty) return false;
      final url = Uri.parse('$_googleUrl?key=$key&q=test&source=en&target=vi');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Load API key from a local-only asset if present, otherwise from env-like runtime
  Future<String?> _loadApiKey() async {
    if (_apiKey != null) return _apiKey;
    // Prefer an asset file that is not committed: assets/secrets/google_translate_key.txt
    try {
      final key = await rootBundle.loadString('assets/secrets/google_translate_key.txt');
      _apiKey = key.trim();
      return _apiKey;
    } catch (_) {}
    // As a fallback, use a const via --dart-define at build time
    const envKey = String.fromEnvironment('GOOGLE_TRANSLATE_API_KEY');
    if (envKey.isNotEmpty) {
      _apiKey = envKey;
      return _apiKey;
    }
    return null;
  }
}
