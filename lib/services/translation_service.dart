import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // For demo purposes, we'll use a simple translation service
  // In production, you would use Google Translate API, Azure Translator, or similar
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';
  
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

      // For demo purposes, if translating to the same language, return original
      if (from == to) {
        return cleanText;
      }

      // Build the request URL
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': cleanText,
        'langpair': '$from|$to',
      });

      // Make the HTTP request
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['responseStatus'] == 200) {
          final translatedText = data['responseData']['translatedText'] as String;
          return translatedText;
        } else {
          throw Exception('Translation API error: ${data['responseDetails']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes, return a fallback translation
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
      final response = await http.get(
        Uri.parse('$_baseUrl?q=test&langpair=en|vi'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
