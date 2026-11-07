package com.focuspet.focuspet

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.media.AudioAttributes
import android.os.PowerManager
import android.os.Vibrator
import android.os.VibratorManager

// Alarma exacta al terminar la sesión: vibra y avisa aunque la pantalla esté apagada
object EndAlarm {
    fun schedule(ctx: Context, at: Long, vibrate: Boolean, mode: Int) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(ctx, EndReceiver::class.java)
            .putExtra("v", vibrate).putExtra("mode", mode)
        val pi = PendingIntent.getBroadcast(
            ctx, 20, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val show = PendingIntent.getActivity(
            ctx, 21, Intent(ctx, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE
        )
        am.setAlarmClock(AlarmManager.AlarmClockInfo(at, show), pi)
    }

    fun cancel(ctx: Context) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        PendingIntent.getBroadcast(
            ctx, 20, Intent(ctx, EndReceiver::class.java),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )?.let { am.cancel(it) }
    }
}

class EndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val app = context.applicationContext
        val vib = intent?.getBooleanExtra("v", true) == true
        val mode = intent?.getIntExtra("mode", 0) ?: 0
        val pr = goAsync()
        val wl = (app.getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "focuspet:end")
        wl.acquire(30_000)
        Thread {
            try {
                Dnd.disable(app)
                waitDndOff(app)
                notifyAlarm(
                    app,
                    if (mode == 2) "☀️ ¡Buenos días!" else "🎉 ¡Sesión terminada!",
                    "Abre focuspet para cobrar tus monedas",
                    vib
                )
                if (vib) {
                    Thread.sleep(500)
                    vibrateLong(app)
                    Thread.sleep(1500)
                }
            } catch (e: Exception) {
            } finally {
                if (wl.isHeld) wl.release()
                pr.finish()
            }
        }.start()
    }

    // espera (máx. 3 s) a que "No molestar" se haya apagado de verdad
    private fun waitDndOff(ctx: Context) {
        if (Build.VERSION.SDK_INT < 23) return
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        var i = 0
        while (i < 15 && nm.currentInterruptionFilter != android.app.NotificationManager.INTERRUPTION_FILTER_ALL) {
            Thread.sleep(200)
            i++
        }
    }

    // aviso tipo alarma: su canal vibra y se salta "No molestar"
    private fun notifyAlarm(ctx: Context, title: String, text: String, vib: Boolean) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        val open = PendingIntent.getActivity(ctx, 11, Intent(ctx, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val pat = longArrayOf(0, 1500, 400, 1500, 400, 1500)
        val b: android.app.Notification.Builder
        if (Build.VERSION.SDK_INT >= 26) {
            val ch = android.app.NotificationChannel("fin_alarma_v1", "Fin de sesión", android.app.NotificationManager.IMPORTANCE_HIGH)
            ch.enableVibration(vib)
            ch.vibrationPattern = pat
            try { ch.setBypassDnd(true) } catch (e: Exception) { }
            nm.createNotificationChannel(ch)
            b = android.app.Notification.Builder(ctx, "fin_alarma_v1")
        } else {
            @Suppress("DEPRECATION")
            b = android.app.Notification.Builder(ctx).setVibrate(pat).setPriority(android.app.Notification.PRIORITY_MAX)
        }
        b.setSmallIcon(ctx.applicationInfo.icon).setContentTitle(title).setContentText(text)
            .setCategory(android.app.Notification.CATEGORY_ALARM).setContentIntent(open).setAutoCancel(true)
        nm.notify(20, b.build())
    }

    // ~60 s a máxima potencia, como alarma (atraviesa "No molestar")
    private fun vibrateLong(ctx: Context) {
        val v: Vibrator = if (Build.VERSION.SDK_INT >= 31) {
            (ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        val t = LongArray(41) { if (it == 0) 0L else if (it % 2 == 1) 2500L else 500L } // 20 pulsos = 60 s
        if (Build.VERSION.SDK_INT >= 26) {
            val amp = IntArray(t.size) { if (it % 2 == 1) 255 else 0 }
            val fx = if (v.hasAmplitudeControl()) VibrationEffect.createWaveform(t, amp, -1)
            else VibrationEffect.createWaveform(t, -1)
            val at = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
            @Suppress("DEPRECATION")
            v.vibrate(fx, at)
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(t, -1)
        }
    }
}
