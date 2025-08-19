# Live Voice Translator - Setup Guide

## 📋 Prerequisites

1. **Flutter SDK** (3.8.1 or higher)
2. **Google Cloud Account** with billing enabled
3. **Google Translate API** access
4. **Google Cloud Speech-to-Text API** access (optional, for enhanced STT)

## 🔑 API Keys Setup

### 1. Google Translate API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable the **Cloud Translation API**
4. Go to "Credentials" → "Create Credentials" → "API Key"
5. Copy the API key

### 2. Google Cloud Speech-to-Text (Optional)

1. In the same Google Cloud project, enable **Cloud Speech-to-Text API**
2. Create a **Service Account**:
   - Go to "IAM & Admin" → "Service Accounts"
   - Click "Create Service Account"
   - Give it a name (e.g., "speech-to-text-service")
   - Grant role: **Cloud Speech Client**
3. Create and download the JSON key file

## 📁 Local Configuration

### Required Files

Create these files in `assets/secrets/` (they are git-ignored for security):

1. **`google_translate_key.txt`**
   ```
   YOUR_GOOGLE_TRANSLATE_API_KEY_HERE
   ```

2. **`gcp_service_account.json`** (optional, for enhanced STT)
   ```json
   {
     "type": "service_account",
     "project_id": "your-project-id",
     "private_key_id": "...",
     "private_key": "...",
     "client_email": "...",
     "client_id": "...",
     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
     "token_uri": "https://oauth2.googleapis.com/token",
     "auth_provider_x509_cert_url": "...",
     "client_x509_cert_url": "..."
   }
   ```

## 🚀 Installation

1. **Install dependencies:**
   ```bash
   cd live_voice_translator
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run -d ios
   ```

## 🔧 Platform-Specific Setup

### Android
- Microphone permissions are already configured in `android/app/src/main/AndroidManifest.xml`
- Minimum SDK: 21 (Android 5.0)

### iOS
- Microphone and speech recognition permissions are configured in `ios/Runner/Info.plist`
- Minimum iOS version: 12.0

## 🧪 Testing

1. **Test Translation Service:**
   - The app will fall back to demo translations if API key is missing
   - Check console for "Missing Google Translate API key" errors

2. **Test Speech Recognition:**
   - Grant microphone permission when prompted
   - Speak clearly in a quiet environment
   - Text should appear in real-time

## 🔐 Security Notes

- **Never commit API keys** to version control
- API key files in `assets/secrets/` are already in `.gitignore`
- For production, consider using environment variables or secure key management

## 📱 Supported Languages

**Input/Output Languages:**
- English (en)
- Chinese/Mandarin (zh)
- Hindi (hi)
- Spanish (es)
- Arabic (ar)
- Bengali (bn)
- French (fr)
- Russian (ru)
- Portuguese (pt)
- Urdu (ur)
- Vietnamese (vi)

## 🐛 Troubleshooting

### Common Issues

1. **"Missing Google Translate API key"**
   - Ensure `assets/secrets/google_translate_key.txt` exists and contains valid API key
   - Check API key has Translation API enabled

2. **Speech recognition not working**
   - Grant microphone permissions
   - Check device microphone is working
   - Try in quieter environment

3. **App crashes on startup**
   - Run `flutter clean && flutter pub get`
   - Check Flutter and Dart SDK versions

4. **Translation showing "(Translation unavailable)"**
   - API key issue or network connectivity
   - App falls back to demo translations for common phrases

### Logs & Debugging

Enable verbose logging:
```bash
flutter run --verbose
```

Check device logs:
```bash
# Android
adb logcat -s flutter

# iOS
flutter logs
```

## 🚀 Next Steps

After setup, you can:
1. Test the full voice → text → translation pipeline
2. Test on different devices and screen sizes
3. Test landscape/portrait orientations
4. Test screen mirroring to external displays
