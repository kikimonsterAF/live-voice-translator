import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:live_voice_translator/providers/translation_provider.dart';

class TranslationDisplayScreen extends StatefulWidget {
  const TranslationDisplayScreen({super.key});

  @override
  State<TranslationDisplayScreen> createState() => _TranslationDisplayScreenState();
}

class _TranslationDisplayScreenState extends State<TranslationDisplayScreen> {
  TranslationProvider? _provider;
  @override
  void initState() {
    super.initState();
    // Clear previous session data and start fresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<TranslationProvider>();
      _provider?.clearTexts(); // Clear any previous translation texts
      _provider?.clearError(); // Clear any previous errors
      _provider?.startListening();
    });
    // Presenter mode: keep screen awake and immersive while on this screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<TranslationProvider>(
          builder: (context, provider, child) {
            return Stack(
              children: [
                // Main content
                Column(
                  children: [
                    // Top bar with back button and language info
                    _buildTopBar(context, provider),
                    
                    // Main translation display area
                    Expanded(
                      child: _buildTranslationArea(provider),
                    ),
                    
                    // Bottom controls (empty for now)
                    _buildBottomControls(context, provider),
                  ],
                ),
                
                // Error overlay
                if (provider.errorMessage.isNotEmpty)
                  _buildErrorOverlay(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, TranslationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              await provider.stopListening();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: Text(
              '${provider.inputLanguage.nativeName} → ${provider.outputLanguage.nativeName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard, color: Colors.white),
            onPressed: () {
              // Optional: Add text input functionality later
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationArea(TranslationProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Translated text (large, center)
          Expanded(
            flex: 3,
            child: Center(
              child: provider.translatedText.isEmpty
                  ? _buildWaitingMessage(provider)
                  : _buildTranslatedText(provider.translatedText),
            ),
          ),
          
          // Original text (small, bottom)
          if (provider.originalText.isNotEmpty)
            _buildOriginalText(provider.originalText),
        ],
      ),
    );
  }

  Widget _buildWaitingMessage(TranslationProvider provider) {
    String message;
    if (provider.isListening) {
      message = 'Listening...\nSpeak clearly and the translation will appear here.';
    } else if (provider.isTranslating) {
      message = 'Translating...';
    } else {
      message = 'Preparing microphone...\nGrant permission when prompted.';
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          provider.isListening ? Icons.mic : Icons.mic_off,
          color: provider.isListening ? Colors.green : Colors.grey,
          size: 64,
        ),
        const SizedBox(height: 24),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTranslatedText(String text) {
    // Get screen orientation and size for better scaling
    final orientation = MediaQuery.of(context).orientation;
    
    // Larger font sizes, especially for landscape mode
    final minFontSize = orientation == Orientation.landscape ? 36.0 : 28.0;
    final maxFontSize = orientation == Orientation.landscape ? 120.0 : 96.0;
    final maxLines = orientation == Orientation.landscape ? 2 : 3;
    
    return AutoSizeText(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      textAlign: TextAlign.center,
      maxLines: maxLines,
      minFontSize: minFontSize,
      maxFontSize: maxFontSize,
      stepGranularity: 4,
    );
  }

  Widget _buildOriginalText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, TranslationProvider provider) {
    return const SizedBox.shrink();
  }

  Widget _buildErrorOverlay(TranslationProvider provider) {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => provider.clearError(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Restore system UI on exit first
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Stop listening and clear session data using cached provider reference
    _provider?.stopListening();
    _provider?.clearTexts(); // Clear translation texts for next session
    _provider?.clearError(); // Clear any errors
    
    super.dispose();
  }
}