package com.focuspet.focuspet

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock

// Lista lofi (res/raw/lofi_1..3): orden aleatorio sin repetir, con fundido cruzado entre pistas.
// El ciclo completo dura ~5 min y se baraja cada vuelta, así el bucle no se nota.
object MusicPlayer {
    private const val FADE = 6000L
    private var cur: MediaPlayer? = null
    private var out: MediaPlayer? = null
    private var am: AudioManager? = null
    private var req: AudioFocusRequest? = null
    private val attrs = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build()
    private var app: Context? = null
    private var vol = 0.6f
    private var fadeT = 0L
    private var last = 0
    private var active = false
    private var paused = false
    private val queue = ArrayList<Int>()
    private var pool = listOf(1, 2, 3)
    private val h = Handler(Looper.getMainLooper())

    private val focus = AudioManager.OnAudioFocusChangeListener { c ->
        when (c) {
            AudioManager.AUDIOFOCUS_LOSS, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                paused = true
                cur?.pause(); out?.pause()
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                paused = false
                cur?.start(); out?.start()
            }
        }
    }

    private val tick = object : Runnable {
        override fun run() {
            if (!active) return
            try {
                val c = cur
                if (c != null && !paused) {
                    if (out == null && c.duration - c.currentPosition <= FADE) {
                        val n = begin(nextTrack(), 0f)
                        if (n != null) {
                            out = c; cur = n; fadeT = SystemClock.uptimeMillis()
                        }
                    }
                    val o = out
                    if (o != null) {
                        val f = ((SystemClock.uptimeMillis() - fadeT) / FADE.toFloat()).coerceIn(0f, 1f)
                        cur?.setVolume(vol * f, vol * f)
                        o.setVolume(vol * (1 - f), vol * (1 - f))
                        if (f >= 1f) { o.release(); out = null }
                    }
                }
            } catch (e: Exception) {
            }
            h.postDelayed(this, 200)
        }
    }

    private fun nextTrack(): Int {
        if (queue.isEmpty()) {
            queue.addAll(pool.shuffled())
            if (queue.first() == last) queue.add(queue.removeAt(0))
        }
        last = queue.removeAt(0)
        return last
    }

    private fun begin(track: Int, v: Float): MediaPlayer? {
        val a = app ?: return null
        val id = a.resources.getIdentifier("lofi_$track", "raw", a.packageName)
        if (id == 0) return null
        return try {
            val p = MediaPlayer()
            p.setAudioAttributes(attrs)
            val afd = a.resources.openRawResourceFd(id)
            p.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            p.prepare()
            p.setWakeMode(a, PowerManager.PARTIAL_WAKE_LOCK)
            p.setVolume(v, v)
            p.start()
            p
        } catch (e: Exception) {
            null
        }
    }

    // Idempotente: si ya suena, no reinicia (así sigue al entrar/salir del modo concentración)
    fun play(ctx: Context, track: Int) {
        if (active) return
        val a = ctx.applicationContext
        app = a
        val m = a.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        am = m
        if (Build.VERSION.SDK_INT >= 26) {
            val r = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs).setOnAudioFocusChangeListener(focus).build()
            req = r
            m.requestAudioFocus(r)
        } else {
            @Suppress("DEPRECATION")
            m.requestAudioFocus(focus, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
        }
        queue.clear()
        last = 0
        if (track >= 4) { // clásica 432 Hz: 6 pistas de ~11 min (más de 1 h sin repetir)
            pool = (4..9).toList()
            queue.addAll(pool.shuffled())
        } else {
            pool = listOf(1, 2, 3)
            queue.add(track.coerceIn(1, 3))
            queue.addAll(pool.filter { it != track }.shuffled())
        }
        val p = begin(nextTrack(), vol) ?: return
        cur = p
        paused = false
        active = true
        h.postDelayed(tick, 200)
    }

    fun stop() {
        active = false
        h.removeCallbacks(tick)
        cur?.release(); out?.release()
        cur = null; out = null
        if (Build.VERSION.SDK_INT >= 26) {
            req?.let { am?.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            am?.abandonAudioFocus(focus)
        }
    }

    fun setVolume(v: Float) {
        vol = v
        if (out == null) cur?.setVolume(v, v)
    }
}
