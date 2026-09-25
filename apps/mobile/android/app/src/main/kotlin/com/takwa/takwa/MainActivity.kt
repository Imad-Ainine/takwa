package com.takwa

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canUseFullScreenIntent" -> result.success(canUseFullScreenIntent())
                else -> result.notImplemented()
            }
        }
    }

    // Android 14 (API 34) takes USE_FULL_SCREEN_INTENT away from apps the Play
    // Store does not classify as an alarm or call app, which is why the Adhan
    // screen stops opening by itself. flutter_local_notifications 18.0.1 can
    // only *request* that permission — asking opens the system page — so the
    // settings screen reads the state here instead and asks only when it is
    // actually missing.
    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return true
        }
        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        return manager?.canUseFullScreenIntent() ?: true
    }

    companion object {
        private const val CHANNEL = "com.takwa/permissions"
    }
}
