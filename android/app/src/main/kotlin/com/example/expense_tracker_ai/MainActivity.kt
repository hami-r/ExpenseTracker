package com.example.expense_tracker_ai

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterFragmentActivity(), EventChannel.StreamHandler {
    private val methodChannelName = "expense_tracker_ai/speech_control"
    private val eventChannelName = "expense_tracker_ai/speech_events"

    private var speechRecognizer: SpeechRecognizer? = null
    private var recognizerIntent: Intent? = null
    private var eventSink: EventChannel.EventSink? = null

    private var manualStop = false
    private var listeningSessionActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> {
                        result.success(SpeechRecognizer.isRecognitionAvailable(this))
                    }

                    "startListening" -> {
                        val args = call.arguments as? Map<*, *>
                        val locale = args?.get("locale") as? String
                        startListening(locale, result)
                    }

                    "stopListening" -> {
                        stopListeningInternal()
                        result.success(true)
                    }

                    "cancelListening" -> {
                        stopListeningInternal()
                        result.success(true)
                    }

                    "destroy" -> {
                        destroyRecognizer()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun ensureRecognizer(locale: String?): Boolean {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            return false
        }

        if (speechRecognizer == null) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
            speechRecognizer?.setRecognitionListener(recognitionListener)
        }

        recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE,
                locale?.takeIf { it.isNotBlank() } ?: Locale.getDefault().toLanguageTag()
            )
            // These values are not guaranteed by all OEM implementations, but can
            // reduce premature cutoff (and repeated start beeps) on some devices.
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 9000L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 5500L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 20000L)
        }

        return true
    }

    private fun hasAudioPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun startListening(locale: String?, result: MethodChannel.Result) {
        if (!hasAudioPermission()) {
            result.error("MIC_PERMISSION", "Microphone permission not granted", null)
            return
        }

        if (!ensureRecognizer(locale)) {
            result.error("NOT_AVAILABLE", "Speech recognizer is not available", null)
            return
        }

        manualStop = false

        try {
            if (listeningSessionActive) {
                speechRecognizer?.cancel()
                listeningSessionActive = false
            }
            speechRecognizer?.startListening(recognizerIntent)
            listeningSessionActive = true
            emitStatus("listening")
            result.success(true)
        } catch (t: Throwable) {
            listeningSessionActive = false
            emitError(-1, t.message ?: "Failed to start listening")
            result.error("START_FAILED", t.message, null)
        }
    }

    private fun stopListeningInternal() {
        manualStop = true
        listeningSessionActive = false
        try {
            speechRecognizer?.stopListening()
        } catch (_: Throwable) {
            try {
                speechRecognizer?.cancel()
            } catch (_: Throwable) {
                // No-op
            }
        }
        emitStatus("notListening")
    }

    private fun emitStatus(status: String) {
        runOnUiThread {
            eventSink?.success(mapOf("type" to "status", "status" to status))
        }
    }

    private fun emitResult(text: String, isFinal: Boolean) {
        runOnUiThread {
            eventSink?.success(
                mapOf(
                    "type" to "result",
                    "text" to text,
                    "final" to isFinal
                )
            )
        }
    }

    private fun emitError(code: Int, message: String) {
        runOnUiThread {
            eventSink?.success(
                mapOf(
                    "type" to "error",
                    "code" to code,
                    "message" to message
                )
            )
        }
    }

    private fun emitRms(level: Double) {
        runOnUiThread {
            eventSink?.success(
                mapOf(
                    "type" to "rms",
                    "value" to level
                )
            )
        }
    }

    private fun errorMessage(error: Int): String {
        return when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "No speech match"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
            SpeechRecognizer.ERROR_SERVER -> "Server error"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Speech timeout"
            else -> "Unknown error"
        }
    }

    private val recognitionListener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            emitStatus("ready")
        }

        override fun onBeginningOfSpeech() {
            emitStatus("listening")
        }

        override fun onRmsChanged(rmsdB: Float) {
            val normalized = ((rmsdB + 2f) / 12f).coerceIn(0f, 1f)
            emitRms(normalized.toDouble())
        }

        override fun onBufferReceived(buffer: ByteArray?) {}

        override fun onEndOfSpeech() {
            listeningSessionActive = false
            emitStatus("endOfSpeech")
        }

        override fun onError(error: Int) {
            listeningSessionActive = false
            val isManualClientError = manualStop && error == SpeechRecognizer.ERROR_CLIENT
            if (isManualClientError) {
                emitStatus("notListening")
                return
            }

            emitError(error, errorMessage(error))
            emitStatus("notListening")
        }

        override fun onResults(results: Bundle?) {
            listeningSessionActive = false
            val spoken = results
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                ?.firstOrNull()
                ?.trim()
                .orEmpty()

            if (spoken.isNotEmpty()) {
                emitResult(spoken, true)
            }
            emitStatus("done")
            emitStatus("notListening")
        }

        override fun onPartialResults(partialResults: Bundle?) {
            val spoken = partialResults
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                ?.firstOrNull()
                ?.trim()
                .orEmpty()

            if (spoken.isNotEmpty()) {
                emitResult(spoken, false)
            }
        }

        override fun onEvent(eventType: Int, params: Bundle?) {}
    }

    private fun destroyRecognizer() {
        manualStop = true
        listeningSessionActive = false
        try {
            speechRecognizer?.cancel()
        } catch (_: Throwable) {
            // No-op
        }
        try {
            speechRecognizer?.destroy()
        } catch (_: Throwable) {
            // No-op
        }
        speechRecognizer = null
        recognizerIntent = null
    }

    override fun onDestroy() {
        destroyRecognizer()
        super.onDestroy()
    }
}
