package com.focuspet.focuspet

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

class BlockerService : AccessibilityService() {

    companion object {
        @Volatile var running = false
        @Volatile var blocking = false
        @Volatile var extra: Set<String> = emptySet() // apps permitidas (modo flexible)
        @Volatile var wantDnd = false // silenciar notificaciones mientras se bloquea

        private fun syncDnd() {
            val ctx = instance?.applicationContext ?: return
            if (wantDnd && blocking) Dnd.enable(ctx) else Dnd.disable(ctx)
        }
        private var instance: BlockerService? = null
        private val handler = Handler(Looper.getMainLooper())
        private val resume = Runnable {
            blocking = true
            syncDnd()
            instance?.bringAppToFront()
        }
        // Llamadas de emergencia y teléfono siempre permitidos
        private val allowed = setOf(
            "com.android.systemui", "com.android.phone", "com.android.server.telecom",
            "com.google.android.dialer", "com.android.dialer", "com.samsung.android.dialer",
            "com.samsung.android.incallui", "com.android.incallui",
            // relojes/alarmas: nunca tapar una alarma
            "com.google.android.deskclock", "com.android.deskclock", "com.sec.android.app.clockpackage", "com.oneplus.deskclock"
        )

        // Apaga la pantalla (bloqueo) 1,5 s después de empezar la sesión
        fun lock() {
            handler.postDelayed({ instance?.lockNow() }, 1500)
        }

        fun block(b: Boolean) {
            handler.removeCallbacks(resume)
            blocking = b
            syncDnd()
        }

        // La pausa se reactiva sola aunque la app esté en segundo plano
        fun pauseFor(ms: Long) {
            blocking = false
            syncDnd()
            handler.removeCallbacks(resume)
            handler.postDelayed(resume, ms)
        }
    }

    override fun onServiceConnected() { running = true; instance = this }

    override fun onUnbind(intent: Intent?): Boolean {
        running = false; instance = null
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val e = event ?: return
        if (!blocking || e.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = e.packageName?.toString() ?: return
        if (pkg == packageName || pkg in allowed || pkg in extra || pkg.contains("inputmethod")) return
        bringAppToFront()
    }

    fun lockNow() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
        }
    }

    fun bringAppToFront() {
        startActivity(
            Intent(this, MainActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        )
    }

    override fun onInterrupt() {}
}
