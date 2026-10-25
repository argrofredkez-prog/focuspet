package com.focuspet.focuspet

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focuspet/blocker")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isEnabled" -> result.success(BlockerService.running)
                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "setBlocking" -> {
                        BlockerService.block(call.arguments as Boolean)
                        result.success(null)
                    }
                    "pause" -> {
                        BlockerService.pauseFor((call.arguments as Number).toLong())
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
