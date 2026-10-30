package com.focuspet.focuspet

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator

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
        Dnd.disable(context)
        MusicPlayer.stop()
        if (intent?.getBooleanExtra("v", true) == true) {
            val v = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            val pattern = longArrayOf(0, 500, 200, 500, 200, 900)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                v.vibrate(pattern, -1)
            }
        }
        val mode = intent?.getIntExtra("mode", 0) ?: 0
        if (mode == 2) {
            Bedtime.notifyText(context, 20, "☀️ ¡Buenos días!", "Abre focuspet para cobrar tus monedas")
        } else {
            Bedtime.notifyText(context, 20, "🎉 ¡Sesión terminada!", "Abre focuspet para cobrar tus monedas")
        }
    }
}
