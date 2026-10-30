package com.focuspet.focuspet

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
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
                    "lockScreen" -> {
                        BlockerService.lock()
                        result.success(null)
                    }
                    "setAllowed" -> {
                        BlockerService.extra = (call.arguments as List<*>).map { it.toString() }.toSet()
                        result.success(null)
                    }
                    "getApps" -> {
                        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                        val apps = packageManager.queryIntentActivities(intent, 0)
                            .map {
                                mapOf(
                                    "name" to it.loadLabel(packageManager).toString(),
                                    "pkg" to it.activityInfo.packageName
                                )
                            }
                            .filter { it["pkg"] != packageName }
                            .sortedBy { it["name"]?.lowercase() }
                        result.success(apps)
                    }
                    "launchApp" -> {
                        val i = packageManager.getLaunchIntentForPackage(call.arguments as String)
                        if (i != null) startActivity(i)
                        result.success(null)
                    }
                    "setReminder" -> {
                        val a = call.arguments as Map<*, *>
                        Bedtime.schedule(
                            applicationContext, (a["id"] as Number).toInt(),
                            (a["h"] as Number).toInt(), (a["m"] as Number).toInt()
                        )
                        result.success(null)
                    }
                    "cancelReminder" -> {
                        Bedtime.cancel(applicationContext, (call.arguments as Number).toInt())
                        result.success(null)
                    }
                    "hasDnd" -> result.success(Dnd.granted(applicationContext))
                    "openDndSettings" -> {
                        if (Build.VERSION.SDK_INT >= 23) {
                            startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                        }
                        result.success(null)
                    }
                    "setDnd" -> {
                        BlockerService.wantDnd = call.arguments as Boolean
                        result.success(null)
                    }
                    "dndRestore" -> {
                        if (!BlockerService.blocking) Dnd.disable(applicationContext)
                        result.success(null)
                    }
                    "musicPlay" -> {
                        MusicPlayer.play(applicationContext, (call.arguments as Number).toInt())
                        result.success(null)
                    }
                    "musicStop" -> {
                        MusicPlayer.stop()
                        result.success(null)
                    }
                    "musicVolume" -> {
                        MusicPlayer.setVolume((call.arguments as Number).toFloat())
                        result.success(null)
                    }
                    "setBrightness" -> {
                        val v = (call.arguments as Number).toFloat()
                        val lp = window.attributes
                        lp.screenBrightness =
                            if (v >= 1f) android.view.WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE else v
                        window.attributes = lp
                        result.success(null)
                    }
                    "scheduleEnd" -> {
                        val m = call.arguments as Map<*, *>
                        EndAlarm.schedule(
                            applicationContext, (m["at"] as Number).toLong(),
                            m["v"] as Boolean, (m["mode"] as Number).toInt()
                        )
                        result.success(null)
                    }
                    "cancelEnd" -> {
                        EndAlarm.cancel(applicationContext)
                        result.success(null)
                    }
                    "setupBedtime" -> {
                        if (Build.VERSION.SDK_INT >= 33 &&
                            checkSelfPermission("android.permission.POST_NOTIFICATIONS") != PackageManager.PERMISSION_GRANTED
                        ) {
                            requestPermissions(arrayOf("android.permission.POST_NOTIFICATIONS"), 1)
                        }
                        Bedtime.restoreAll(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
