package com.focuspet.focuspet

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import kotlin.math.min
import kotlin.math.pow

// Música de fondo estilo videojuego clásico (chiptune), generada en el móvil.
// Cada nivel estrena melodía (todas de dominio público) y cada 4 niveles sube el ritmo.
object ChipMusic {
    private const val SR = 22050

    // (nota MIDI, duración en unidades); 0 = silencio
    private class Song(
        val notes: Array<Pair<Int, Int>>,
        val unitsPerBar: Int,
        val roots: IntArray,
        val unitSec: Double,
        val bassStep: Int,
        val shift: Int
    )

    private val songs = arrayOf(
        // «Korobeiniki» (canción popular rusa)
        Song(
            arrayOf(
                76 to 2, 71 to 1, 72 to 1, 74 to 2, 72 to 1, 71 to 1,
                69 to 2, 69 to 1, 72 to 1, 76 to 2, 74 to 1, 72 to 1,
                71 to 3, 72 to 1, 74 to 2, 76 to 2,
                72 to 2, 69 to 2, 69 to 4,
                74 to 3, 77 to 1, 81 to 2, 79 to 1, 77 to 1,
                76 to 3, 72 to 1, 76 to 2, 74 to 1, 72 to 1,
                71 to 2, 71 to 1, 72 to 1, 74 to 2, 76 to 2,
                72 to 2, 69 to 2, 69 to 4
            ),
            8, intArrayOf(52, 57, 52, 57, 50, 48, 52, 57), 0.2, 1, 12
        ),
        // «Minueto en Sol» (Petzold)
        Song(
            arrayOf(
                74 to 2, 67 to 1, 69 to 1, 71 to 1, 72 to 1,
                74 to 2, 67 to 2, 67 to 2,
                76 to 2, 72 to 1, 74 to 1, 76 to 1, 78 to 1,
                79 to 2, 67 to 2, 67 to 2,
                72 to 2, 74 to 1, 72 to 1, 71 to 1, 69 to 1,
                71 to 2, 72 to 1, 71 to 1, 69 to 1, 67 to 1,
                66 to 2, 67 to 1, 69 to 1, 71 to 1, 67 to 1,
                69 to 6
            ),
            6, intArrayOf(55, 55, 48, 55, 48, 55, 50, 55), 0.22, 1, 12
        ),
        // «Para Elisa» (Beethoven)
        Song(
            arrayOf(
                76 to 1, 75 to 1, 76 to 1, 75 to 1, 76 to 1, 71 to 1,
                74 to 1, 72 to 1, 69 to 2, 0 to 1, 60 to 1,
                64 to 1, 69 to 1, 71 to 2, 0 to 1, 64 to 1,
                68 to 1, 71 to 1, 72 to 2, 0 to 1, 64 to 1,
                76 to 1, 75 to 1, 76 to 1, 75 to 1, 76 to 1, 71 to 1,
                74 to 1, 72 to 1, 69 to 2, 0 to 1, 60 to 1,
                64 to 1, 69 to 1, 71 to 2, 0 to 1, 64 to 1,
                72 to 1, 71 to 1, 69 to 4
            ),
            6, intArrayOf(57, 57, 52, 57, 57, 57, 52, 57), 0.13, 2, 0
        ),
        // «Himno a la alegría» (Beethoven)
        Song(
            arrayOf(
                76 to 2, 76 to 2, 77 to 2, 79 to 2,
                79 to 2, 77 to 2, 76 to 2, 74 to 2,
                72 to 2, 72 to 2, 74 to 2, 76 to 2,
                76 to 3, 74 to 1, 74 to 4,
                76 to 2, 76 to 2, 77 to 2, 79 to 2,
                79 to 2, 77 to 2, 76 to 2, 74 to 2,
                72 to 2, 72 to 2, 74 to 2, 76 to 2,
                74 to 3, 72 to 1, 72 to 4
            ),
            8, intArrayOf(48, 55, 48, 55, 48, 55, 48, 55), 0.22, 2, 0
        )
    )

    private var track: AudioTrack? = null
    private var wanted = false
    private var level = 0
    private var gen = 0
    private val cache = LinkedHashMap<Int, ShortArray>()

    private fun hz(m: Int) = 440.0 * 2.0.pow((m - 69) / 12.0)

    private fun build(song: Song, speed: Double): ShortArray {
        val unit = (SR * song.unitSec / speed).toInt()
        val units = song.roots.size * song.unitsPerBar
        val total = units * unit * 2
        val buf = FloatArray(total)
        for (pass in 0..1) {
            val off = pass * units * unit
            val duty = if (pass == 0) 0.5 else 0.25
            val up = if (pass == 1) song.shift else 0
            var pos = 0
            for ((n, d) in song.notes) {
                val len = d * unit
                if (n > 0) {
                    val f = hz(n + up)
                    for (i in 0 until len) {
                        val idx = off + pos + i
                        if (idx >= total) break
                        val ph = (f * i / SR) % 1.0
                        val env = minOf(1f, i / 80f) * (if (i > len * 0.8) (len - i) / (len * 0.2f) else 1f)
                        buf[idx] += (if (ph < duty) 0.20f else -0.20f) * env
                    }
                }
                pos += len
            }
            val steps = units / song.bassStep
            for (s in 0 until steps) {
                val bar = (s * song.bassStep) / song.unitsPerBar
                val m = song.roots[min(bar, song.roots.size - 1)] + (if (s % 2 == 1) 7 else 0)
                val f = hz(m)
                val len = song.bassStep * unit
                val start = off + s * len
                for (i in 0 until len) {
                    val idx = start + i
                    if (idx >= total) break
                    val ph = (f * i / SR) % 1.0
                    val tri = (if (ph < 0.5) 4 * ph - 1 else 3 - 4 * ph).toFloat()
                    val env = (1f - i / len.toFloat() * 0.5f) * minOf(1f, i / 60f)
                    buf[idx] += tri * 0.17f * env
                }
            }
        }
        val out = ShortArray(total)
        for (i in 0 until total) {
            out[i] = (buf[i].coerceIn(-1f, 1f) * 30000).toInt().toShort()
        }
        return out
    }

    private fun play() {
        val my: Int
        val lv: Int
        synchronized(this) {
            gen++
            my = gen
            lv = level
        }
        Thread {
            val si = lv % songs.size
            val tier = min(lv / songs.size, 4)
            val key = si * 10 + tier
            var pcm: ShortArray?
            synchronized(cache) { pcm = cache[key] }
            if (pcm == null) {
                pcm = try { build(songs[si], 1.0 + 0.1 * tier) } catch (e: Throwable) { null }
                val made = pcm
                if (made != null) {
                    synchronized(cache) {
                        cache[key] = made
                        if (cache.size > 4) cache.remove(cache.keys.first())
                    }
                }
            }
            val data = pcm
            synchronized(this@ChipMusic) {
                if (data != null && wanted && gen == my) {
                    try {
                        track?.stop()
                        track?.release()
                    } catch (e: Throwable) {
                    }
                    track = null
                    try {
                        @Suppress("DEPRECATION")
                        val t = AudioTrack(
                            AudioManager.STREAM_MUSIC, SR, AudioFormat.CHANNEL_OUT_MONO,
                            AudioFormat.ENCODING_PCM_16BIT, data.size * 2, AudioTrack.MODE_STATIC
                        )
                        t.write(data, 0, data.size)
                        t.setLoopPoints(0, data.size, -1)
                        t.setVolume(0.5f)
                        t.play()
                        track = t
                    } catch (e: Throwable) {
                    }
                }
            }
        }.start()
    }

    fun start(lv: Int) {
        synchronized(this) {
            wanted = true
            level = lv
        }
        play()
    }

    fun setLevel(lv: Int) {
        val change: Boolean
        synchronized(this) {
            change = wanted && lv != level
            level = lv
        }
        if (change) play()
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
            gen++
            try { track?.stop(); track?.release() } catch (e: Throwable) { }
            track = null
        }
    }
}
