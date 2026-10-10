package com.takwa

import android.app.ActivityManager
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import com.pravera.flutter_foreground_task.models.ForegroundServiceAction
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.models.ForegroundTaskData
import com.pravera.flutter_foreground_task.service.ForegroundService
import com.pravera.flutter_foreground_task.utils.ForegroundServiceUtils

/**
 * Where the Dart side records whether the user wants Takwa's background
 * service to come back on its own. It has to be a native file because a
 * BOOT_COMPLETED receiver runs with no Flutter engine attached: Dart code
 * only exists once something launches an activity or a service, which is
 * exactly the decision this flag is meant to precede. `shared_preferences`
 * is not used on purpose — its storage layout is the plugin's business, and
 * `SettingsPrefsBridge` mirrors some booleans as strings, so reading that
 * file from Kotlin would be a silent-dependency trap rather than a contract.
 */
object TakwaBootPrefs {
    private const val PREFS_NAME = "com.takwa.boot"
    private const val KEY_AUTOSTART = "bootAutostartEnabled"

    fun isAutoStartEnabled(context: Context): Boolean = context
        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        .getBoolean(KEY_AUTOSTART, false)

    fun setAutoStartEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_AUTOSTART, enabled)
            .apply()
    }
}

/**
 * Second chance for the adhan background service on real devices.
 *
 * flutter_foreground_task already restarts its service on `BOOT_COMPLETED`
 * (`autoRunOnBoot`), but that single attempt is fragile on phones: the plugin
 * catches `ForegroundServiceStartNotAllowedException`, logs it and gives up,
 * and OEM launch managers (HONOR/Huawei "App launch", Xiaomi "Auto-start")
 * routinely let the broadcast through while refusing the background service
 * start it triggers. When that happens nothing retries until the user opens
 * the app again — which is the "I rebooted my phone and the Adhan screen
 * stopped appearing by itself" report.
 *
 * So this receiver does not start the service on the boot broadcast itself
 * (that would race the plugin's own attempt and rebuild the task isolate for
 * nothing). It schedules one delayed retry, and the retry only starts the
 * service if it is genuinely not running. The same shape covers
 * `MY_PACKAGE_REPLACED`, where the update kills the service and the restart
 * depends on options the *previous* build persisted.
 */
class TakwaBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            ACTION_BOOT_COMPLETED_HTC,
            ACTION_BOOT_COMPLETED_HTC_ALT -> scheduleRetry(context, BOOT_RETRY_DELAY_MS)

            Intent.ACTION_MY_PACKAGE_REPLACED -> scheduleRetry(context, UPDATE_RETRY_DELAY_MS)

            ACTION_ENSURE_BACKGROUND -> ensureBackgroundService(context)
        }
    }

    // Starts the plugin's foreground service, but only for a user who asked
    // for it and only while it is actually missing. Every guard below is a
    // case where starting it would be wrong rather than merely useless.
    private fun ensureBackgroundService(context: Context) {
        if (!TakwaBootPrefs.isAutoStartEnabled(context)) return

        // The callback handle is written by `startService()`, so without it
        // the task has never been configured on this install and the service
        // would start with nothing to run.
        if (ForegroundTaskData.getData(context).callbackHandle == null) return

        // Respect an explicit stop from the app (`OverlayBackgroundService.
        // stop()`), which the plugin records as API_STOP.
        if (ForegroundServiceStatus.getData(context).isCorrectlyStopped()) return

        if (ForegroundServiceUtils.isSetStopWithTaskFlag(context)) return

        // A foreground service must show a notification on API 26+; with the
        // channel silenced by the user the start either fails or posts
        // nothing, and the next app launch re-arms it anyway.
        val notifications = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as? NotificationManager
        if (notifications?.areNotificationsEnabled() == false) return

        if (isServiceRunning(context)) return

        try {
            // Same contract the plugin's own RebootReceiver uses: the action
            // is read back inside `onStartCommand` to decide what to build.
            ForegroundServiceStatus.setData(context, ForegroundServiceAction.REBOOT)
            val service = Intent(context, ForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(service)
            } else {
                context.startService(service)
            }
            Log.i(TAG, "Background service re-armed after boot/update")
        } catch (e: Exception) {
            Log.e(TAG, "Boot retry failed: ${e.message}")
        }
    }

    private fun scheduleRetry(context: Context, delayMs: Long) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        try {
            // Inexact on purpose: this is a safety net minutes after boot, and
            // an exact alarm would consume the app's daily exact-alarm budget
            // that the prayer notifications themselves depend on.
            alarm.setAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + delayMs,
                retryPendingIntent(context),
            )
        } catch (e: Exception) {
            Log.e(TAG, "Boot retry could not be scheduled: ${e.message}")
        }
    }

    private fun retryPendingIntent(context: Context): PendingIntent {
        // Explicit component, so no intent-filter entry is needed for the
        // custom action and no other app can trigger the retry.
        val intent = Intent(context, TakwaBootReceiver::class.java)
            .setAction(ACTION_ENSURE_BACKGROUND)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_RETRY,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    @Suppress("DEPRECATION")
    private fun isServiceRunning(context: Context): Boolean {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE)
            as? ActivityManager ?: return false
        // Deprecated, but since API 26 it still reports the caller's own
        // services, which is all this check needs.
        return manager.getRunningServices(Int.MAX_VALUE)?.any {
            it.service.className == FOREGROUND_SERVICE_CLASS
        } == true
    }

    private companion object {
        const val TAG = "TakwaBootReceiver"

        const val ACTION_ENSURE_BACKGROUND = "com.takwa.action.ENSURE_BACKGROUND"

        // HTC's legacy fast-boot broadcast.
        const val ACTION_BOOT_COMPLETED_HTC = "android.intent.action.QUICKBOOT_POWERON"
        const val ACTION_BOOT_COMPLETED_HTC_ALT = "com.htc.intent.action.QUICKBOOT_POWERON"

        const val FOREGROUND_SERVICE_CLASS =
            "com.pravera.flutter_foreground_task.service.ForegroundService"

        const val REQUEST_CODE_RETRY = 4211

        // Long enough for the system (and the plugin's own attempt) to have
        // settled, short enough to survive the boot window.
        const val BOOT_RETRY_DELAY_MS = 3 * 60 * 1000L

        const val UPDATE_RETRY_DELAY_MS = 60 * 1000L
    }
}
