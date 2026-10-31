package com.halo.halo

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * `halo/sleep` (start, stop, isRunning) and `halo/sleep/minutes`, the
 * stream of `{minute, count}` the service records. Minutes recorded while
 * nothing listens are held and sent when Dart listens again.
 */
object SleepChannel {
    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private val pending = ArrayDeque<Map<String, Int>>()
    private var openListener: (() -> Unit)? = null

    fun attach(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        val methods = MethodChannel(messenger, "halo/sleep")
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val startMs = (call.argument<Number>("startMs"))?.toLong()
                        ?: System.currentTimeMillis()
                    val intent = Intent(app, SleepService::class.java)
                        .putExtra(SleepService.EXTRA_START_MS, startMs)
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            app.startForegroundService(intent)
                        } else {
                            app.startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("start_failed", e.message, null)
                    }
                }
                "stop" -> {
                    if (SleepService.running) {
                        app.startService(
                            Intent(app, SleepService::class.java).setAction(SleepService.ACTION_STOP),
                        )
                    }
                    result.success(null)
                }
                "isRunning" -> result.success(SleepService.running)
                else -> result.notImplemented()
            }
        }
        openListener = { methods.invokeMethod("open", null) }
        EventChannel(messenger, "halo/sleep/minutes").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    sink = events
                    while (pending.isNotEmpty()) events.success(pending.removeFirst())
                }

                override fun onCancel(arguments: Any?) {
                    sink = null
                }
            },
        )
    }

    /** From the service's sensor thread: hop to the main thread first. */
    fun emit(minute: Int, count: Int) {
        val event = mapOf("minute" to minute, "count" to count)
        main.post {
            val current = sink
            if (current != null) current.success(event) else pending.addLast(event)
        }
    }

    fun open() {
        openListener?.invoke()
    }
}
