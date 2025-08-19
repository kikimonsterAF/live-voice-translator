import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live_voice_translator/models/language.dart';
import 'package:live_voice_translator/providers/translation_provider.dart';
import 'package:live_voice_translator/screens/translation_display_screen.dart';
import 'package:live_voice_translator/widgets/ad_banner.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            Widget title({required bool compact}) => Column(
                  children: [
                    Text(
                      'Real Time Speech Translator',
                      style: TextStyle(
                        fontSize: compact ? 26 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Real-time voice translations for presentations',
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );

            Widget languagePicker({
              required String label,
              required Language current,
              required ValueChanged<Language> onChanged,
            }) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Language>(
                          value: current,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          items: SupportedLanguages.languages.map((language) {
                            return DropdownMenuItem<Language>(
                              value: language,
                              child: Text('${language.nativeName} (${language.name})',
                                  softWrap: true),
                            );
                          }).toList(),
                          onChanged: (Language? newLanguage) {
                            if (newLanguage != null) onChanged(newLanguage);
                          },
                        ),
                      ),
                    ),
                  ],
                );

            final padding = EdgeInsets.all(isLandscape ? 16 : 24);

            return Padding(
              padding: padding,
              child: isLandscape
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Centered header across the full width
                        Center(child: title(compact: true)),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left column: pickers
                            Expanded(
                              flex: 1,
                              child: Consumer<TranslationProvider>(
                                builder: (context, provider, _) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    languagePicker(
                                      label: 'Speak in:',
                                      current: provider.inputLanguage,
                                      onChanged: provider.setInputLanguage,
                                    ),
                                    const SizedBox(height: 16),
                                    languagePicker(
                                      label: 'Translate to:',
                                      current: provider.outputLanguage,
                                      onChanged: provider.setOutputLanguage,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right column: start + tip
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const TranslationDisplayScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Start Translation',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: const Text(
                                      'Tip: Use a quiet environment and allow mic permissions.',
                                      style: TextStyle(fontSize: 12, color: Colors.black87),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Consumer<TranslationProvider>(
                      builder: (context, provider, _) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          title(compact: false),
                          const SizedBox(height: 40),
                          languagePicker(
                            label: 'Speak in:',
                            current: provider.inputLanguage,
                            onChanged: provider.setInputLanguage,
                          ),
                          const SizedBox(height: 24),
                          languagePicker(
                            label: 'Translate to:',
                            current: provider.outputLanguage,
                            onChanged: provider.setOutputLanguage,
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TranslationDisplayScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Start Translation',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!provider.isPremium) ...[
                            const SizedBox(height: 8),
                            const AdBanner(
                              adUnitId: 'ca-app-pub-9080166502892502/6438845792',
                            ),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Text(
                              'Tip: This app works best in quiet environments. Make sure to grant microphone permissions when prompted.',
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
