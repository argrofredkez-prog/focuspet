package com.focuspet.focuspet

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import kotlin.math.PI
import kotlin.math.pow
import kotlin.math.sin

// Música de fondo estilo videojuego clásico (chiptune). Melodía popular rusa «Korobeiniki»
// (dominio público) con arreglo propio. Se genera en el móvil: no necesita archivos.
object ChipMusic {
    private const val SR = 22050
    private var track: AudioTrack? = null
    private var wanted = false
    private var building = false

    // (nota MIDI, duración en corcheas); 0 = silencio
    private val mel = arrayOf(
        76 to 2, 71 to 1, 72 to 1, 74 to 2, 72 to 1, 71 to 1,
        69 to 2, 69 to 1, 72 to 1, 76 to 2, 74 to 1, 72 to 1,
        71 to 3, 72 to 1, 74 to 2, 76 to 2,
        72 to 2, 69 to 2, 69 to 4,
        74 to 3, 77 to 1, 81 to 2, 79 to 1, 77 to 1,
        76 to 3, 72 to 1, 76 to 2, 74 to 1, 72 to 1,
        71 to 2, 71 to 1, 72 to 1, 74 to 2, 76 to 2,
        72 to 2, 69 to 2, 69 to 4
    )
    private val bass = intArrayOf(52, 57, 52, 57, 50, 48, 52, 57) // una raíz por compás

    private fun hz(m: Int) = 440.0 * 2.0.pow((m - 69) / 12.0)

    private fun build(): ShortArray {
        val eighth = (SR * 0.2).toInt() // 150 bpm
        val total = 8 * 8 * eighth * 2 // 2 vueltas (la 2.ª, una octava arriba y más brillante)
        val buf = FloatArray(total)
        for (pass in 0..1) {
            val off = pass * 64 * eighth
            var pos = 0
            for ((n, d) in mel) {
                val len = d * eighth
                if (n > 0) {
                    val f = hz(n + (if (pass == 1) 12 else 0))
                    val duty = if (pass == 0) 0.5 else 0.25
                    for (i in 0 until len) {
                        val ph = (f * i / SR) % 1.0
                        val env = minOf(1f, i / 80f) * (if (i > len * 0.8) (len - i) / (len * 0.2f) else 1f)
                        buf[off + pos + i] += (if (ph < duty) 0.20f else -0.20f) * env
                    }
                }
                pos += len
            }
            for (bar in 0 until 8) {
                for (k in 0 until 8) {
                    val m = bass[bar] + (if (k % 2 == 1) 7 else 0)
                    val f = hz(m)
                    val start = off + (bar * 8 + k) * eighth
                    for (i in 0 until eighth) {
                        val ph = (f * i / SR) % 1.0
                        val tri = (if (ph < 0.5) 4 * ph - 1 else 3 - 4 * ph).toFloat()
                        val env = (1f - i / eighth.toFloat() * 0.5f) * minOf(1f, i / 60f)
                        buf[start + i] += tri * 0.17f * env
                    }
                }
            }
        }
        val out = ShortArray(total)
        for (i in 0 until total) {
            out[i] = (buf[i].coerceIn(-1f, 1f) * 30000).toInt().toShort()
        }
        return out
    }

    fun start() {
        synchronized(this) {
            wanted = true
            if (track != null || building) return
            building = true
        }
        Thread {
            val pcm = try { build() } catch (e: Throwable) { null }
            synchronized(this) {
                building = false
                if (pcm != null && wanted && track == null) {
                    try {
                        @Suppress("DEPRECATION")
                        val t = AudioTrack(
                            AudioManager.STREAM_MUSIC, SR, AudioFormat.CHANNEL_OUT_MONO,
                            AudioFormat.ENCODING_PCM_16BIT, pcm.size * 2, AudioTrack.MODE_STATIC
                        )
                        t.write(pcm, 0, pcm.size)
                        t.setLoopPoints(0, pcm.size, -1)
                        t.setVolume(0.5f)
                        t.play()
                        track = t
                    } catch (e: Throwable) {
                    }
                }
            }
        }.start()
    }

    fun pause() {
        synchronized(this) { try { track?.pause() } catch (e: Throwable) { } }
    }

    fun resume() {
        synchronized(this) { try { if (wanted) track?.play() } catch (e: Throwable) { } }
    }

    fun stop() {
        synchronized(this) {
            wanted = false
            try { track?.stop(); track?.release() } catch (e: Throwable) { }
            track = null
        }
    }
}
