class Language {
  final String code;
  final String name;
  final String nativeName;
  String get localeCode {
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
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'th':
        return 'th-TH';
      case 'id':
        return 'id-ID';
      case 'ms':
        return 'ms-MY';
      case 'fil':
        return 'fil-PH';
      default:
        return 'en-US';
    }
  }

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  @override
  String toString() => nativeName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class SupportedLanguages {
  static const List<Language> languages = [
    Language(code: 'en', name: 'English', nativeName: 'English'),
    Language(code: 'zh', name: 'Chinese (Mandarin)', nativeName: '中文 (普通话)'),
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
    Language(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    Language(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
    Language(code: 'fr', name: 'French', nativeName: 'Français'),
    Language(code: 'ru', name: 'Russian', nativeName: 'Русский'),
    Language(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
    Language(code: 'ur', name: 'Urdu', nativeName: 'اردو'),
    Language(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt'),
    // Additional major Asian languages
    Language(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    Language(code: 'ko', name: 'Korean', nativeName: '한국어'),
    Language(code: 'th', name: 'Thai', nativeName: 'ไทย'),
    Language(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia'),
    Language(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu'),
    Language(code: 'fil', name: 'Filipino', nativeName: 'Filipino'),
  ];

  static Language get defaultInputLanguage => languages.firstWhere((l) => l.code == 'en');
  static Language get defaultOutputLanguage => languages.firstWhere((l) => l.code == 'vi');

  static Language? getLanguageByCode(String code) {
    try {
      return languages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }
}
