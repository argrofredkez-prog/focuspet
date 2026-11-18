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
import org.json.JSONArray
import java.util.Calendar

// La mascota avisa cada X tiempo para volver a estudiar (nunca en horas de sueño ni durante una sesión)
object PetReminder {
    private fun prefs(ctx: Context) = ctx.getSharedPreferences("focuspet_native", Context.MODE_PRIVATE)

    fun configure(ctx: Context, on: Boolean, every: Int, from: Int, to: Int, data: String) {
        prefs(ctx).edit().putBoolean("pr_on", on).putInt("pr_every", every)
            .putInt("pr_from", from).putInt("pr_to", to).putString("pr_data", data).apply()
        if (on) scheduleNext(ctx) else cancel(ctx)
    }

    private fun pi(ctx: Context): PendingIntent = PendingIntent.getBroadcast(
        ctx, 30, Intent(ctx, PetReminderReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    fun scheduleNext(ctx: Context) {
        val every = prefs(ctx).getInt("pr_every", 120).coerceAtLeast(15)
        val at = System.currentTimeMillis() + every * 60_000L
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi(ctx))
        } else {
            am.set(AlarmManager.RTC_WAKEUP, at, pi(ctx))
        }
    }

    fun cancel(ctx: Context) {
        (ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pi(ctx))
    }

    fun restore(ctx: Context) {
        if (prefs(ctx).getBoolean("pr_on", false)) scheduleNext(ctx)
    }

    private fun inSleep(from: Int, to: Int): Boolean {
        val c = Calendar.getInstance()
        val m = c.get(Calendar.HOUR_OF_DAY) * 60 + c.get(Calendar.MINUTE)
        return if (from <= to) m in from until to else (m >= from || m < to)
    }

    fun fire(ctx: Context) {
        val p = prefs(ctx)
        if (!p.getBoolean("pr_on", false)) return
        scheduleNext(ctx)
        if (System.currentTimeMillis() < p.getLong("sess_end", 0L)) return // sesión en marcha
        if (inSleep(p.getInt("pr_from", 23 * 60), p.getInt("pr_to", 8 * 60))) return // dormir
        var name = "Tu mascota"
        var text = "Vuelve al trabajo, es hora de conseguirlo 💪"
        try {
            val arr = JSONArray(p.getString("pr_data", "[]"))
            if (arr.length() > 0) {
                val o = arr.getJSONObject((0 until arr.length()).random())
                name = o.getString("name")
                val ph = o.getJSONArray("phrases")
                if (ph.length() > 0) text = ph.getString((0 until ph.length()).random())
            }
        } catch (e: Throwable) {
        }
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val open = PendingIntent.getActivity(ctx, 31, Intent(ctx, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val b: Notification.Builder
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(NotificationChannel("pet_rem", "Avisos de mascotas", NotificationManager.IMPORTANCE_DEFAULT))
            b = Notification.Builder(ctx, "pet_rem")
        } else {
            b = Notification.Builder(ctx)
        }
        b.setSmallIcon(ctx.applicationInfo.icon).setContentTitle("🐾 $name").setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text)).setContentIntent(open).setAutoCancel(true)
        nm.notify(30, b.build())
    }
}

class PetReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try { PetReminder.fire(context.applicationContext) } catch (e: Throwable) { }
    }
}
