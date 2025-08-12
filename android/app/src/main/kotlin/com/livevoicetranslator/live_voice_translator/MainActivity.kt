package com.livevoicetranslator.live_voice_translator

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognizerIntent
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "flutter.native/speech"
    }

    private lateinit var channel: MethodChannel
    private val REQ_CODE_SPEECH = 1001
    private val REQ_CODE_PERMISSION = 2001

    private var pendingStart: Boolean = false
    private var pendingLanguage: String = "en-US"
    private var recognizer: SpeechRecognizer? = null
    private var recognitionIntent: Intent? = null
    private var isListening: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // no-op here; we handle results via deprecated callbacks for compatibility
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    if (hasRecordAudioPermission()) {
                        result.success(true)
                    } else {
                        pendingStart = false
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.RECORD_AUDIO),
                            REQ_CODE_PERMISSION
                        )
                        result.success(false)
                    }
                }
                "startListening" -> {
                    val language = call.argument<String>("language") ?: "en-US"
                    if (!hasRecordAudioPermission()) {
                        pendingStart = true
                        pendingLanguage = language
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.RECORD_AUDIO),
                            REQ_CODE_PERMISSION
                        )
                        result.success(false)
                    } else {
                        startContinuousRecognizer(language)
                        result.success(true)
                    }
                }
                "stopListening" -> {
                    stopContinuousRecognizer()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasRecordAudioPermission(): Boolean {
        val status = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        )
        return status == PackageManager.PERMISSION_GRANTED
    }

    private fun startContinuousRecognizer(language: String) {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            channel.invokeMethod(
                "onSpeechError",
                mapOf("error" to "Speech recognition not available on this device")
            )
            return
        }
        if (recognizer == null) {
            recognizer = SpeechRecognizer.createSpeechRecognizer(this)
            recognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {
                    if (isListening) restartRecognizer()
                }
                override fun onError(error: Int) {
                    // Restart on transient errors
                    if (isListening) restartRecognizer()
                }
                override fun onResults(results: Bundle) {
                    val texts = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val text = texts?.firstOrNull().orEmpty()
                    if (text.isNotEmpty()) {
                        channel.invokeMethod("onSpeechResult", mapOf("text" to text))
                    }
                    if (isListening) restartRecognizer()
                }
                override fun onPartialResults(partialResults: Bundle) {
                    val texts = partialResults.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val text = texts?.firstOrNull().orEmpty()
                    if (text.isNotEmpty()) {
                        channel.invokeMethod("onSpeechResult", mapOf("text" to text))
                    }
                }
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
        }
        if (recognitionIntent == null) {
            recognitionIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            }
        }
        recognitionIntent?.putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
        isListening = true
        recognizer?.startListening(recognitionIntent)
    }

    private fun restartRecognizer() {
        recognizer?.cancel()
        recognitionIntent?.let { intent ->
            recognizer?.startListening(intent)
        }
    }

    private fun stopContinuousRecognizer() {
        isListening = false
        recognizer?.stopListening()
        recognizer?.cancel()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_CODE_SPEECH) {
            if (resultCode == RESULT_OK) {
                val matches = data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                val text = matches?.firstOrNull().orEmpty()
                channel.invokeMethod("onSpeechResult", mapOf("text" to text))
            } else {
                channel.invokeMethod("onSpeechError", mapOf("error" to "Speech canceled"))
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_CODE_PERMISSION) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            channel.invokeMethod("onPermissionResult", mapOf("granted" to granted))
            if (granted && pendingStart) {
                pendingStart = false
                startContinuousRecognizer(pendingLanguage)
            }
        }
    }
}
