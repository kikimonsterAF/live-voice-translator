class Language {
  final String code;
  final String name;
  final String nativeName;

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
  ];

  static Language get defaultInputLanguage => languages[0]; // English
  static Language get defaultOutputLanguage => languages[10]; // Vietnamese

  static Language? getLanguageByCode(String code) {
    try {
      return languages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }
}
