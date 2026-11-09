package com.example.petits_champions

import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
	private lateinit var textToSpeech: TextToSpeech
	private var isTextToSpeechReady = false

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		textToSpeech = TextToSpeech(applicationContext) { status ->
			isTextToSpeechReady = status == TextToSpeech.SUCCESS
		}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "petits_champions/speech")
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"speak" -> {
						val text = call.argument<String>("text")
						val languageTag = call.argument<String>("language")

						if (text.isNullOrBlank() || languageTag.isNullOrBlank()) {
							result.error("invalid_arguments", "Text and language are required.", null)
						} else if (!isTextToSpeechReady) {
							result.error("tts_not_ready", "Text-to-speech is not ready.", null)
						} else {
							val languageStatus = textToSpeech.setLanguage(Locale.forLanguageTag(languageTag))
							if (languageStatus == TextToSpeech.LANG_MISSING_DATA ||
								languageStatus == TextToSpeech.LANG_NOT_SUPPORTED
							) {
								result.error("tts_language_unavailable", "The selected voice is unavailable.", null)
							} else {
								textToSpeech.setSpeechRate(0.4f)
								val speakStatus = textToSpeech.speak(
									text,
									TextToSpeech.QUEUE_FLUSH,
									null,
									"petits-champions-word"
								)
								if (speakStatus == TextToSpeech.ERROR) {
									result.error("tts_speak_failed", "Speech could not be started.", null)
								} else {
									result.success(null)
								}
							}
						}
					}

					"stop" -> {
						if (isTextToSpeechReady) textToSpeech.stop()
						result.success(null)
					}

					else -> result.notImplemented()
				}
			}
	}

	override fun onDestroy() {
		if (::textToSpeech.isInitialized) {
			textToSpeech.stop()
			textToSpeech.shutdown()
		}
		super.onDestroy()
	}
}
