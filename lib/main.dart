import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live_voice_translator/screens/language_selection_screen.dart';
import 'package:live_voice_translator/providers/translation_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:live_voice_translator/providers/premium_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const LiveVoiceTranslatorApp());
}

class LiveVoiceTranslatorApp extends StatelessWidget {
  const LiveVoiceTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumProvider()..init()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
      ],
      child: MaterialApp(
        title: 'Live Voice Translator',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          // High contrast theme for better readability
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        home: const LanguageSelectionScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}