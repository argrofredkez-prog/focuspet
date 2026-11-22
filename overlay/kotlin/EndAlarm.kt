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
        ctx.getSharedPreferences("focuspet_native", Context.MODE_PRIVATE).edit().putLong("sess_end", at).apply()
        am.setAlarmClock(AlarmManager.AlarmClockInfo(at, show), pi)
    }

    fun cancel(ctx: Context) {
        ctx.getSharedPreferences("focuspet_native", Context.MODE_PRIVATE).edit().putLong("sess_end", 0L).apply()
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        PendingIntent.getBroadcast(
            ctx, 20, Intent(ctx, EndReceiver::class.java),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )?.let { am.cancel(it) }
    }

    private fun vibrator(ctx: Context): Vibrator? = try {
        if (Build.VERSION.SDK_INT >= 31) {
            (ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    } catch (e: Throwable) {
        null
    }

    // 2 vibraciones largas como alarma (se detiene sola)
    fun buzz(ctx: Context) {
        val v = vibrator(ctx) ?: return
        val t = longArrayOf(0, 900, 450, 900) // 2 vibraciones largas y se detiene
        var ok = false
        if (Build.VERSION.SDK_INT >= 26) {
            try {
                val amp = IntArray(t.size) { if (it % 2 == 1) 255 else 0 }
                val fx = if (v.hasAmplitudeControl()) VibrationEffect.createWaveform(t, amp, -1)
                else VibrationEffect.createWaveform(t, -1)
                val at = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
                v.vibrate(fx, at)
                ok = true
            } catch (e: Throwable) {
            }
            if (!ok) {
                try {
                    v.vibrate(VibrationEffect.createWaveform(t, -1))
                    ok = true
                } catch (e: Throwable) {
                }
            }
        }
        if (!ok) {
            try {
                v.vibrate(t, -1)
            } catch (e: Throwable) {
            }
        }
    }

    // aviso tipo alarma (canal nuevo: los canales viejos no se pueden cambiar)
    fun notifyEnd(ctx: Context, mode: Int, vib: Boolean) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        val open = PendingIntent.getActivity(ctx, 11, Intent(ctx, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val b: android.app.Notification.Builder
        if (Build.VERSION.SDK_INT >= 26) {
            val ch = android.app.NotificationChannel("fin_alarma_v4", "Fin de sesión", android.app.NotificationManager.IMPORTANCE_HIGH)
            ch.enableVibration(false) // vibra solo buzz(): exactamente 2 largas
            try { ch.setBypassDnd(true) } catch (e: Exception) { }
            nm.createNotificationChannel(ch)
            b = android.app.Notification.Builder(ctx, "fin_alarma_v4")
        } else {
            b = android.app.Notification.Builder(ctx).setPriority(android.app.Notification.PRIORITY_MAX)
        }
        b.setSmallIcon(ctx.applicationInfo.icon)
            .setContentTitle(if (mode == 2) "☀️ ¡Buenos días!" else "🎉 ¡Sesión terminada!")
            .setContentText("Abre FOKUS ON! para cobrar tus monedas")
            .setCategory(android.app.Notification.CATEGORY_ALARM).setContentIntent(open).setAutoCancel(true)
        nm.notify(20, b.build())
    }

    // espera (máx. 1,5 s) a que "No molestar" se haya apagado
    private fun waitDndOff(ctx: Context) {
        if (Build.VERSION.SDK_INT < 23) return
        try {
            val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            var i = 0
            while (i < 8 && nm.currentInterruptionFilter != android.app.NotificationManager.INTERRUPTION_FILTER_ALL) {
                Thread.sleep(200)
                i++
            }
        } catch (e: Throwable) {
        }
    }

    // Cada paso va por separado: si uno falla, los demás se hacen igual
    fun fire(ctx: Context, vib: Boolean, mode: Int) {
        // evita repetir si la alarma y la app avisan a la vez
        val p = ctx.getSharedPreferences("focuspet_native", Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        synchronized(this) {
            if (now - p.getLong("last_fire", 0L) < 20_000L) return
            p.edit().putLong("last_fire", now).apply()
        }
        try { Dnd.disable(ctx) } catch (e: Throwable) { }
        waitDndOff(ctx)
        if (vib) buzz(ctx)
        try { notifyEnd(ctx, mode, vib) } catch (e: Throwable) { }
    }
}

class EndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val app = context.applicationContext
        val vib = intent?.getBooleanExtra("v", true) != false
        val mode = intent?.getIntExtra("mode", 0) ?: 0
        val pr = goAsync()
        val wl = (app.getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "focuspet:end")
        wl.acquire(20_000)
        Thread {
            try {
                EndAlarm.fire(app, vib, mode)
            } catch (e: Throwable) {
            } finally {
                if (wl.isHeld) wl.release()
                pr.finish()
            }
        }.start()
    }
}
