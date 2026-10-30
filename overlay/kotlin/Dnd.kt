package com.focuspet.focuspet

import android.app.NotificationManager
import android.content.Context
import android.os.Build

// Silencia todas las notificaciones menos llamadas (y alarmas) mientras dura la concentración
object Dnd {
    private fun prefs(ctx: Context) = ctx.getSharedPreferences("focuspet_native", Context.MODE_PRIVATE)
    private fun nm(ctx: Context) = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun granted(ctx: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm(ctx).isNotificationPolicyAccessGranted

    fun enable(ctx: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || !granted(ctx)) return
        val p = prefs(ctx)
        if (p.getBoolean("dnd_on", false)) return
        val n = nm(ctx)
        val old = n.notificationPolicy
        p.edit().putInt("dnd_filter", n.currentInterruptionFilter)
            .putInt("dnd_cat", old.priorityCategories)
            .putInt("dnd_call", old.priorityCallSenders)
            .putInt("dnd_msg", old.priorityMessageSenders)
            .putBoolean("dnd_on", true).apply()
        n.notificationPolicy = NotificationManager.Policy(
            NotificationManager.Policy.PRIORITY_CATEGORY_CALLS or NotificationManager.Policy.PRIORITY_CATEGORY_REPEAT_CALLERS or NotificationManager.Policy.PRIORITY_CATEGORY_ALARMS,
            NotificationManager.Policy.PRIORITY_SENDERS_ANY, NotificationManager.Policy.PRIORITY_SENDERS_ANY
        )
        n.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
    }

    fun disable(ctx: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val p = prefs(ctx)
        if (!p.getBoolean("dnd_on", false)) return
        p.edit().putBoolean("dnd_on", false).apply()
        if (!granted(ctx)) return
        val n = nm(ctx)
        n.notificationPolicy = NotificationManager.Policy(
            p.getInt("dnd_cat", 0), p.getInt("dnd_call", 0), p.getInt("dnd_msg", 0)
        )
        n.setInterruptionFilter(p.getInt("dnd_filter", NotificationManager.INTERRUPTION_FILTER_ALL))
    }
}
