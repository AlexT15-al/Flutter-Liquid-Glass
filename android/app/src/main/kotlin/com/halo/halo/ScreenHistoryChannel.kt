package com.halo.halo

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `halo/screen_history`: when the screen went on and off and the phone was
 * unlocked, from Android's own usage history, which it keeps for days.
 *
 * Reading it needs Usage Access, a special permission the user grants on its
 * own page in Settings; nothing has to run in the night to collect it.
 *
 * Events come back as `[epochMs, type]` pairs, type being 0 screen on,
 * 1 screen off, 2 unlock, 3 lock.
 */
object ScreenHistoryChannel {
    fun attach(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        MethodChannel(messenger, "halo/screen_history").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasAccess" -> result.success(hasAccess(app))
                "openSettings" -> {
                    openSettings(context)
                    result.success(null)
                }
                "events" -> {
                    val from = call.argument<Number>("fromMs")?.toLong()
                    val to = call.argument<Number>("toMs")?.toLong()
                    if (from == null || to == null) {
                        result.error("bad_args", "Missing range.", null)
                    } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P || !hasAccess(app)) {
                        result.success(emptyList<List<Long>>())
                    } else {
                        result.success(events(app, from, to))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasAccess(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            @Suppress("DEPRECATION")
            ops.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openSettings(context: Context) {
        // Straight to Halo's switch where the system allows it; otherwise the
        // list of apps.
        val direct = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            .setData(Uri.parse("package:${context.packageName}"))
        val list = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        for (intent in listOf(direct, list)) {
            try {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            } catch (_: Exception) {
            }
        }
    }

    private fun events(context: Context, from: Long, to: Long): List<List<Long>> {
        val usage = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usage.queryEvents(from, to)
        val event = UsageEvents.Event()
        val out = ArrayList<List<Long>>()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val type = when (event.eventType) {
                UsageEvents.Event.SCREEN_INTERACTIVE -> 0L
                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> 1L
                UsageEvents.Event.KEYGUARD_HIDDEN -> 2L
                UsageEvents.Event.KEYGUARD_SHOWN -> 3L
                else -> continue
            }
            out.add(listOf(event.timeStamp, type))
        }
        return out
    }
}
