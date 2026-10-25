package dev.repera.mobile

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale

/** Voz española instalada. Audio focus exclusivo transitorio, nunca duck:
 * intenta pausar otras apps durante la frase y libera al terminar/error. */
internal class LiveSpokenGuidance(context: Context) {
    private val audio=context.getSystemService(AudioManager::class.java)
    private var ready=false
    private val focus=AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
        .setOnAudioFocusChangeListener { if(it==AudioManager.AUDIOFOCUS_LOSS) stop() }.build()
    private val tts=TextToSpeech(context.applicationContext) { status -> ready=status==TextToSpeech.SUCCESS }
    init {
        tts.setOnUtteranceProgressListener(object:UtteranceProgressListener() {
            override fun onStart(id:String?) {}
            override fun onDone(id:String?) {audio.abandonAudioFocusRequest(focus)}
            @Deprecated("TTS legacy callback") override fun onError(id:String?) {audio.abandonAudioFocusRequest(focus)}
        })
    }
    fun speak(message:String):Boolean {
        if(!ready || tts.isSpeaking) return false
        val language=tts.setLanguage(Locale("es","ES"))
        if(language==TextToSpeech.LANG_MISSING_DATA || language==TextToSpeech.LANG_NOT_SUPPORTED) return false
        val offline = tts.voices?.filter {
            it.locale.language == "es" && it.locale.country == "ES" && !it.isNetworkConnectionRequired
        }?.maxByOrNull { it.quality } ?: return false
        tts.voice = offline
        if(audio.requestAudioFocus(focus)!=AudioManager.AUDIOFOCUS_REQUEST_GRANTED) return false
        tts.setSpeechRate(1.0f)
        val result=tts.speak(message,TextToSpeech.QUEUE_FLUSH,null,"repera-live-guidance")
        if(result!=TextToSpeech.SUCCESS) audio.abandonAudioFocusRequest(focus)
        return result==TextToSpeech.SUCCESS
    }
    fun stop() {tts.stop();audio.abandonAudioFocusRequest(focus)}
    fun close() {stop();tts.shutdown();ready=false}
}
