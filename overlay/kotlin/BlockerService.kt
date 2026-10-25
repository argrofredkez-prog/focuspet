package com.focuspet.focuspet

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

class BlockerService : AccessibilityService() {

    companion object {
        @Volatile var running = false
        @Volatile var blocking = false
        private var instance: BlockerService? = null
        private val handler = Handler(Looper.getMainLooper())
        private val resume = Runnable {
            blocking = true
            instance?.bringAppToFront()
        }
        // Llamadas de emergencia y teléfono siempre permitidos
        private val allowed = setOf(
            "com.android.systemui", "com.android.phone", "com.android.server.telecom",
            "com.google.android.dialer", "com.android.dialer", "com.samsung.android.dialer",
            "com.samsung.android.incallui", "com.android.incallui"
        )

        fun block(b: Boolean) {
            handler.removeCallbacks(resume)
            blocking = b
        }

        // La pausa se reactiva sola aunque la app esté en segundo plano
        fun pauseFor(ms: Long) {
            blocking = false
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
        if (pkg == packageName || pkg in allowed || pkg.contains("inputmethod")) return
        bringAppToFront()
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
