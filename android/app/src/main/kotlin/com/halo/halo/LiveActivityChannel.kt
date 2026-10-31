package com.halo.halo

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `halo/live_activity`: the live workout notification, driven from Dart.
 *
 * - `start`: starts the workout service with the first state
 * - `update`: reposts the notification under the same id
 * - `end`: stops the service and takes the notification down
 *
 * The other way, it tells Dart about Pause, Resume and taps on the
 * notification.
 */
object LiveActivityChannel {
    private const val NAME = "halo/live_activity"
    private var channel: MethodChannel? = null
    private var running = false

    fun attach(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        channel = MethodChannel(messenger, NAME).also {
            it.setMethodCallHandler { call, result -> handle(app, call, result) }
        }
    }

    fun send(method: String, argument: Any?) {
        channel?.invokeMethod(method, argument)
    }

    private fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start", "update" -> {
                val map = call.arguments as? Map<*, *>
                if (map == null) {
                    result.error("bad_args", "Missing state.", null)
                    return
                }
                val state = WorkoutState.fromMap(map)
                if (call.method == "start" || !running) start(context, state) else update(context, state)
                result.success(null)
            }
            "end" -> {
                end(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun start(context: Context, state: WorkoutState) {
        running = true
        val intent = Intent(context, WorkoutService::class.java).putExtras(state.toBundle())
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        } catch (_: Exception) {
            // Not allowed to start a service right now: show it anyway.
            update(context, state)
        }
    }

    private fun update(context: Context, state: WorkoutState) {
        context.getSystemService(NotificationManager::class.java)
            ?.notify(WorkoutNotification.ID, WorkoutNotification.build(context, state))
    }

    private fun end(context: Context) {
        running = false
        context.stopService(Intent(context, WorkoutService::class.java))
        context.getSystemService(NotificationManager::class.java)?.cancel(WorkoutNotification.ID)
    }
}
