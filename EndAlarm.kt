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
            @Suppress("DEPRECATION")
            ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    } catch (e: Throwable) {
        null
    }

    // Vibra YA (antes de tocar "No molestar" o avisos): ~60 s como alarma
    fun buzz(ctx: Context) {
        val v = vibrator(ctx) ?: return
        val t = LongArray(41) { if (it == 0) 0L else if (it % 2 == 1) 2500L else 500L }
        var ok = false
        if (Build.VERSION.SDK_INT >= 26) {
            try {
                val amp = IntArray(t.size) { if (it % 2 == 1) 255 else 0 }
                val fx = if (v.hasAmplitudeControl()) VibrationEffect.createWaveform(t, amp, -1)
                else VibrationEffect.createWaveform(t, -1)
                val at = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
                @Suppress("DEPRECATION")
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
                @Suppress("DEPRECATION")
                v.vibrate(t, -1)
            } catch (e: Throwable) {
            }
        }
    }

    // aviso tipo alarma (canal nuevo: los canales viejos no se pueden cambiar)
    fun notifyEnd(ctx: Context, mode: Int, vib: Boolean) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        val open = PendingIntent.getActivity(ctx, 11, Intent(ctx, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val pat = longArrayOf(0, 1500, 400, 1500, 400, 1500)
        val b: android.app.Notification.Builder
        if (Build.VERSION.SDK_INT >= 26) {
            val ch = android.app.NotificationChannel("fin_alarma_v3", "Fin de sesión", android.app.NotificationManager.IMPORTANCE_HIGH)
            ch.enableVibration(true)
            ch.vibrationPattern = pat
            try { ch.setBypassDnd(true) } catch (e: Exception) { }
            nm.createNotificationChannel(ch)
            b = android.app.Notification.Builder(ctx, "fin_alarma_v3")
        } else {
            @Suppress("DEPRECATION")
            b = android.app.Notification.Builder(ctx).setVibrate(pat).setPriority(android.app.Notification.PRIORITY_MAX)
        }
        b.setSmallIcon(ctx.applicationInfo.icon)
            .setContentTitle(if (mode == 2) "☀️ ¡Buenos días!" else "🎉 ¡Sesión terminada!")
            .setContentText("Abre FOKUS ONIT! para cobrar tus monedas")
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
        try { Dnd.disable(ctx) } catch (e: Throwable) { }
        waitDndOff(ctx)
        try { notifyEnd(ctx, mode, vib) } catch (e: Throwable) { }
        if (vib) buzz(ctx)
    }
}

class EndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val app = context.applicationContext
        val vib = intent?.getBooleanExtra("v", true) != false
        val mode = intent?.getIntExtra("mode", 0) ?: 0
        // vibra al instante, sin esperar a nada
        if (vib) EndAlarm.buzz(app)
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
