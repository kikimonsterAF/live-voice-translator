import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:live_voice_translator/providers/translation_provider.dart';

class TranslationDisplayScreen extends StatefulWidget {
  const TranslationDisplayScreen({super.key});

  @override
  State<TranslationDisplayScreen> createState() => _TranslationDisplayScreenState();
}

class _TranslationDisplayScreenState extends State<TranslationDisplayScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _showTextInput = false;

  @override
  void initState() {
    super.initState();
    // Start listening automatically when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TranslationProvider>().startListening();
    });
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
                    
                    // Text input area (shown when toggled)
                    if (_showTextInput) _buildTextInputArea(provider),
                    
                    // Bottom controls
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
            icon: Icon(
              _showTextInput ? Icons.keyboard_hide : Icons.keyboard,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showTextInput = !_showTextInput;
              });
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

  Widget _buildTextInputArea(TranslationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type text to translate...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 3,
            onSubmitted: (text) => _translateText(provider, text),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _translateText(provider, _textController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Translate'),
          ),
        ],
      ),
    );
  }

  void _translateText(TranslationProvider provider, String text) {
    if (text.trim().isNotEmpty) {
      provider.setOriginalText(text.trim());
      provider.translateText(text.trim());
      _textController.clear();
    }
  }

  Widget _buildWaitingMessage(TranslationProvider provider) {
    String message;
    if (provider.isListening) {
      message = 'Listening...\nUse the yellow button to separate phrases or the keyboard icon to type.';
    } else if (provider.isTranslating) {
      message = 'Translating...';
    } else {
      message = 'Preparing microphone...\nUse the keyboard icon to type if needed.';
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
    final screenSize = MediaQuery.of(context).size;
    
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Yellow interrupt button (main control)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => provider.interruptPhrase(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24),
                elevation: 6,
              ),
              child: const Icon(
                Icons.pause,
                size: 40,
              ),
            ),
          ),
          
          // Clear button (smaller, secondary)
          ElevatedButton(
            onPressed: () => provider.clearTexts(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
              elevation: 4,
            ),
            child: const Icon(
              Icons.clear,
              size: 24,
            ),
          ),
        ],
      ),
    );
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
    _textController.dispose();
    context.read<TranslationProvider>().stopListening();
    super.dispose();
  }
}