package com.focuspet.focuspet

import android.content.Context
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.PowerManager

// Reproduce las pistas lofi (res/raw/lofi_1..3) en bucle; se pausa si entra una llamada
object MusicPlayer {
    private var mp: MediaPlayer? = null
    private var am: AudioManager? = null
    private var vol = 0.6f
    private val focus = AudioManager.OnAudioFocusChangeListener { c ->
        when (c) {
            AudioManager.AUDIOFOCUS_LOSS, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> mp?.pause()
            AudioManager.AUDIOFOCUS_GAIN -> mp?.start()
        }
    }

    fun play(ctx: Context, track: Int) {
        stop()
        val app = ctx.applicationContext
        val id = app.resources.getIdentifier("lofi_$track", "raw", app.packageName)
        if (id == 0) return
        val a = app.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        am = a
        a.requestAudioFocus(focus, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
        val p = MediaPlayer.create(app, id) ?: return
        p.isLooping = true
        p.setVolume(vol, vol)
        p.setWakeMode(app, PowerManager.PARTIAL_WAKE_LOCK)
        p.start()
        mp = p
    }

    fun stop() {
        mp?.release()
        mp = null
        am?.abandonAudioFocus(focus)
    }

    fun setVolume(v: Float) {
        vol = v
        mp?.setVolume(v, v)
    }
}
