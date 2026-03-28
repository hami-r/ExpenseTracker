package com.example.expense_tracker_ai

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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
    companion object {
        private const val ERROR_TOO_MANY_REQUESTS = 10
        private const val ERROR_SERVER_DISCONNECTED = 11
        private const val ERROR_LANGUAGE_NOT_SUPPORTED = 12
        private const val ERROR_LANGUAGE_UNAVAILABLE = 13
    }

    private val methodChannelName = "expense_tracker_ai/speech_control"
    private val eventChannelName = "expense_tracker_ai/speech_events"

    private var speechRecognizer: SpeechRecognizer? = null
    private var recognizerIntent: Intent? = null
    private var eventSink: EventChannel.EventSink? = null

    private var manualStop = false
    private var listeningSessionActive = false
    private var continuousListeningActive = false
    private var speechSessionCounter = 0L
    private var activeSpeechSessionId: Long? = null
    private var activeLocaleTag: String? = null
    private var segmentedSessionRequested = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private var restartRunnable: Runnable? = null

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
                        cancelListeningInternal()
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

    private fun ensureRecognizer(locale: String?, recreate: Boolean = false): Boolean {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            return false
        }

        activeLocaleTag = locale?.takeIf { it.isNotBlank() } ?: Locale.getDefault().toLanguageTag()
        segmentedSessionRequested = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
        if (recreate || speechRecognizer == null) {
            teardownRecognizer()
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
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 20000L)
            putExtra(
                RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS,
                4000L
            )
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 60000L)
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE,
                activeLocaleTag
            )

            if (segmentedSessionRequested) {
                putExtra(
                    RecognizerIntent.EXTRA_SEGMENTED_SESSION,
                    RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS
                )
            }
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

        if (!ensureRecognizer(locale, recreate = true)) {
            result.error("NOT_AVAILABLE", "Speech recognizer is not available", null)
            return
        }

        clearPendingRestart()
        manualStop = false
        continuousListeningActive = true
        speechSessionCounter += 1
        activeSpeechSessionId = speechSessionCounter

        try {
            startRecognizerAttempt()
            result.success(activeSpeechSessionId?.toInt())
        } catch (t: Throwable) {
            continuousListeningActive = false
            listeningSessionActive = false
            activeSpeechSessionId = null
            emitError(-1, t.message ?: "Failed to start listening")
            result.error("START_FAILED", t.message, null)
        }
    }

    private fun stopListeningInternal() {
        clearPendingRestart()
        manualStop = true
        continuousListeningActive = false
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
        emitStatus("processing")
    }

    private fun cancelListeningInternal() {
        clearPendingRestart()
        manualStop = true
        continuousListeningActive = false
        listeningSessionActive = false
        try {
            speechRecognizer?.cancel()
        } catch (_: Throwable) {
            // No-op
        }
        finishLogicalSession()
    }

    private fun startRecognizerAttempt() {
        speechRecognizer?.startListening(recognizerIntent)
        listeningSessionActive = true
        emitStatus("listening")
    }

    private fun clearPendingRestart() {
        restartRunnable?.let(mainHandler::removeCallbacks)
        restartRunnable = null
    }

    private fun shouldAutoRestart(error: Int): Boolean {
        if (manualStop || !continuousListeningActive || activeSpeechSessionId == null) {
            return false
        }

        return error == SpeechRecognizer.ERROR_NO_MATCH ||
            error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT ||
            error == SpeechRecognizer.ERROR_RECOGNIZER_BUSY ||
            error == ERROR_SERVER_DISCONNECTED
    }

    private fun scheduleRestart(forceRecreate: Boolean = false, delayMs: Long = 700L) {
        if (manualStop || !continuousListeningActive || activeSpeechSessionId == null) {
            return
        }

        clearPendingRestart()
        restartRunnable = Runnable {
            restartRunnable = null

            if (manualStop || !continuousListeningActive || activeSpeechSessionId == null) {
                return@Runnable
            }

            if (!ensureRecognizer(activeLocaleTag, recreate = forceRecreate)) {
                emitError(
                    SpeechRecognizer.ERROR_CLIENT,
                    "Speech recognizer is not available"
                )
                finishLogicalSession()
                return@Runnable
            }

            try {
                startRecognizerAttempt()
            } catch (t: Throwable) {
                if (!forceRecreate && ensureRecognizer(activeLocaleTag, recreate = true)) {
                    try {
                        startRecognizerAttempt()
                        return@Runnable
                    } catch (_: Throwable) {
                        // Fall through to emit a final error below.
                    }
                }

                emitError(-1, t.message ?: "Failed to restart listening")
                finishLogicalSession()
            }
        }
        mainHandler.postDelayed(restartRunnable!!, delayMs)
    }

    private fun finishLogicalSession(emitDone: Boolean = false) {
        clearPendingRestart()
        continuousListeningActive = false
        listeningSessionActive = false

        if (emitDone) {
            emitStatus("done")
        }
        emitStatus("notListening")
        activeSpeechSessionId = null
        activeLocaleTag = null
        segmentedSessionRequested = false
    }

    private fun emitStatus(status: String) {
        runOnUiThread {
            eventSink?.success(
                mapOf(
                    "type" to "status",
                    "status" to status,
                    "sessionId" to activeSpeechSessionId
                )
            )
        }
    }

    private fun emitResult(text: String, isFinal: Boolean) {
        runOnUiThread {
            eventSink?.success(
                mapOf(
                    "type" to "result",
                    "text" to text,
                    "final" to isFinal,
                    "sessionId" to activeSpeechSessionId
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
                    "message" to message,
                    "sessionId" to activeSpeechSessionId
                )
            )
        }
    }

    private fun emitRms(level: Double) {
        runOnUiThread {
            eventSink?.success(
                mapOf(
                    "type" to "rms",
                    "value" to level,
                    "sessionId" to activeSpeechSessionId
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
            ERROR_TOO_MANY_REQUESTS -> "Too many speech requests"
            ERROR_SERVER_DISCONNECTED -> "Speech service disconnected"
            ERROR_LANGUAGE_NOT_SUPPORTED -> "Language not supported"
            ERROR_LANGUAGE_UNAVAILABLE -> "Language unavailable"
            else -> "Unknown error ($error)"
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
            if (manualStop) {
                emitStatus("processing")
            }
        }

        override fun onSegmentResults(segmentResults: Bundle) {
            val spoken = segmentResults
                .getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                ?.firstOrNull()
                ?.trim()
                .orEmpty()

            if (spoken.isNotEmpty()) {
                emitResult(spoken, true)
            }
        }

        override fun onEndOfSegmentedSession() {
            listeningSessionActive = false

            if (manualStop || !continuousListeningActive) {
                finishLogicalSession(emitDone = true)
                return
            }

            scheduleRestart(delayMs = 350L)
        }

        override fun onError(error: Int) {
            listeningSessionActive = false
            val isManualClientError = manualStop && error == SpeechRecognizer.ERROR_CLIENT
            if (isManualClientError) {
                finishLogicalSession()
                return
            }

            if (shouldAutoRestart(error)) {
                val forceRecreate =
                    error == SpeechRecognizer.ERROR_RECOGNIZER_BUSY ||
                        error == ERROR_SERVER_DISCONNECTED
                val restartDelay =
                    if (error == SpeechRecognizer.ERROR_RECOGNIZER_BUSY) 1200L else 700L
                scheduleRestart(forceRecreate = forceRecreate, delayMs = restartDelay)
                return
            }

            emitError(error, errorMessage(error))
            finishLogicalSession()
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

            if (manualStop || !continuousListeningActive) {
                finishLogicalSession(emitDone = true)
                return
            }

            scheduleRestart()
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

    private fun teardownRecognizer() {
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

    private fun destroyRecognizer() {
        clearPendingRestart()
        manualStop = true
        continuousListeningActive = false
        listeningSessionActive = false
        activeSpeechSessionId = null
        activeLocaleTag = null
        segmentedSessionRequested = false
        teardownRecognizer()
    }

    override fun onDestroy() {
        destroyRecognizer()
        super.onDestroy()
    }
}
