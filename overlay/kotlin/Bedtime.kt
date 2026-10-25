package com.focuspet.focuspet

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

// Avisos diarios: id 1 = dormir, 2 = entrenar, 3 = estudiar
object Bedtime {
    private const val CHANNEL = "bedtime"

    private fun prefs(ctx: Context) =
        ctx.getSharedPreferences("focuspet_native", Context.MODE_PRIVATE)

    fun schedule(ctx: Context, id: Int, h: Int, m: Int) {
        prefs(ctx).edit().putInt("r$id", h * 60 + m).apply()
        val c = Calendar.getInstance()
        c.set(Calendar.HOUR_OF_DAY, h)
        c.set(Calendar.MINUTE, m)
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        if (c.timeInMillis <= System.currentTimeMillis()) c.add(Calendar.DAY_OF_YEAR, 1)
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(ctx, BedtimeReceiver::class.java)
            .putExtra("id", id).putExtra("h", h).putExtra("m", m)
        val pi = PendingIntent.getBroadcast(
            ctx, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, c.timeInMillis, pi)
        } else {
            am.set(AlarmManager.RTC_WAKEUP, c.timeInMillis, pi)
        }
    }

    fun cancel(ctx: Context, id: Int) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        PendingIntent.getBroadcast(
            ctx, id, Intent(ctx, BedtimeReceiver::class.java),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )?.let { am.cancel(it) }
        prefs(ctx).edit().remove("r$id").apply()
    }

    fun restoreAll(ctx: Context) {
        for (id in 1..3) {
            val t = prefs(ctx).getInt("r$id", -1)
            if (t >= 0) schedule(ctx, id, t / 60, t % 60)
        }
    }

    fun notifyText(ctx: Context, nid: Int, title: String, text: String) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val open = PendingIntent.getActivity(
            ctx, 10, Intent(ctx, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE
        )
        val b: Notification.Builder
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, "Avisos", NotificationManager.IMPORTANCE_HIGH)
            )
            b = Notification.Builder(ctx, CHANNEL)
        } else {
            b = Notification.Builder(ctx)
        }
        b.setSmallIcon(ctx.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(open)
            .setAutoCancel(true)
        nm.notify(nid, b.build())
    }
}

class BedtimeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val id = intent?.getIntExtra("id", 1) ?: 1
        val h = intent?.getIntExtra("h", 23) ?: 23
        val m = intent?.getIntExtra("m", 30) ?: 30
        val d = Calendar.getInstance().get(Calendar.DAY_OF_WEEK)
        when (id) {
            1 -> {
                // Viernes y sábado por la noche no se avisa (fin de semana)
                if (d != Calendar.FRIDAY && d != Calendar.SATURDAY) {
                    Bedtime.notifyText(context, 1, "🌙 Hora de dormir", "Abre la app y empieza el modo dormir 😴")
                }
            }
            2 -> Bedtime.notifyText(context, 2, "🏋️ Hora de entrenar", "¡Muévete un poco, tu animal y tú lo merecéis!")
            else -> Bedtime.notifyText(context, 3, "📚 Hora de estudiar", "Abre la app y empieza tu sesión de estudio ✨")
        }
        Bedtime.schedule(context, id, h, m)
    }
}

// Reprograma los avisos tras reiniciar el móvil
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Bedtime.restoreAll(context)
    }
}
