package com.halo.halo

import android.app.Activity
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationChannelGroup
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat
import java.util.Calendar

/**
 * `halo/notifications`: the reminders the app planned for the coming week,
 * shown at their time with the app closed.
 *
 * Each one carries a check, done just before it would show, against the
 * state the app last sent (today's water, meals, workouts, steps, the last
 * weigh-in): a reminder with nothing left to say is dropped. The evening
 * steps reminder adds what the step counter has counted since the app last
 * ran; the morning one reads last night from the screen history, the same
 * way the app does, and looks again later if the phone has not been picked
 * up yet.
 */
object Reminders {
    private const val PREFS = "halo_reminders"
    private const val KEY_PLAN = "plan"
    private const val KEY_STATE = "state"
    private const val KEY_IDS = "ids"
    const val ACTION_FIRE = "com.halo.halo.REMINDER"
    const val EXTRA_ID = "id"
    const val EXTRA_ROUTE = "halo_route"
    private const val GROUP = "reminders"
    private const val ACCENT = 0xFF4A8F00.toInt()

    private var channel: MethodChannel? = null
    private var launchRoute: String? = null

    fun attach(activity: Activity, messenger: BinaryMessenger) {
        val app = activity.applicationContext
        channel = MethodChannel(messenger, "halo/notifications").also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        @Suppress("UNCHECKED_CAST")
                        val list = call.arguments as? List<Map<String, Any?>> ?: emptyList()
                        val plan = JSONArray()
                        for (item in list) plan.put(JSONObject(item))
                        prefs(app).edit().putString(KEY_PLAN, plan.toString()).apply()
                        scheduleAll(app)
                        result.success(null)
                    }
                    "state" -> {
                        @Suppress("UNCHECKED_CAST")
                        val map = call.arguments as? Map<String, Any?> ?: emptyMap()
                        val state = state(app)
                        for ((k, v) in map) state.put(k, JSONObject.wrap(v))
                        prefs(app).edit().putString(KEY_STATE, state.toString()).apply()
                        result.success(null)
                    }
                    "exactAllowed" -> result.success(exactAllowed(app))
                    "openExactSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            open(
                                activity,
                                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                                    .setData(Uri.parse("package:${app.packageName}")),
                            )
                        }
                        result.success(null)
                    }
                    "openSettings" -> {
                        open(
                            activity,
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, app.packageName),
                        )
                        result.success(null)
                    }
                    "launchRoute" -> {
                        result.success(launchRoute)
                        launchRoute = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /** The intent that started the activity: kept until the app asks for it. */
    fun onLaunch(intent: Intent?) {
        launchRoute = intent?.getStringExtra(EXTRA_ROUTE) ?: launchRoute
    }

    /** A tap while the app runs: straight to it. */
    fun onNewIntent(intent: Intent): Boolean {
        val route = intent.getStringExtra(EXTRA_ROUTE) ?: return false
        val channel = channel
        if (channel == null) launchRoute = route else channel.invokeMethod("open", route)
        return true
    }

    private fun open(activity: Activity, intent: Intent) {
        try {
            activity.startActivity(intent)
        } catch (_: Exception) {
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun plan(context: Context): JSONArray =
        try {
            JSONArray(prefs(context).getString(KEY_PLAN, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }

    private fun state(context: Context): JSONObject =
        try {
            JSONObject(prefs(context).getString(KEY_STATE, "{}") ?: "{}")
        } catch (_: Exception) {
            JSONObject()
        }

    private fun exactAllowed(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarms.canScheduleExactAlarms()
    }

    private fun alarmIntent(context: Context, id: Int, flags: Int): PendingIntent? =
        PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, ReminderReceiver::class.java)
                .setAction(ACTION_FIRE)
                .putExtra(EXTRA_ID, id),
            PendingIntent.FLAG_IMMUTABLE or flags,
        )

    /** Every reminder to come, as an alarm; the ones no longer planned, gone. */
    fun scheduleAll(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val old = prefs(context).getString(KEY_IDS, "") ?: ""
        for (id in old.split(',').mapNotNull { it.toIntOrNull() }) {
            alarmIntent(context, id, PendingIntent.FLAG_NO_CREATE)?.let {
                alarms.cancel(it)
                it.cancel()
            }
        }
        val now = System.currentTimeMillis()
        val plan = plan(context)
        val ids = ArrayList<Int>()
        for (i in 0 until plan.length()) {
            val item = plan.optJSONObject(i) ?: continue
            val at = item.optLong("at")
            if (at <= now) continue
            val id = item.optInt("id")
            set(context, alarms, id, at)
            ids.add(id)
        }
        prefs(context).edit().putString(KEY_IDS, ids.joinToString(",")).apply()
    }

    private fun set(context: Context, alarms: AlarmManager, id: Int, at: Long) {
        val pending = alarmIntent(context, id, PendingIntent.FLAG_UPDATE_CURRENT) ?: return
        if (exactAllowed(context)) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        }
    }

    /** An alarm went off: check, then show or drop. [done] when finished. */
    fun fire(context: Context, id: Int, done: () -> Unit) {
        val plan = plan(context)
        var item: JSONObject? = null
        for (i in 0 until plan.length()) {
            val candidate = plan.optJSONObject(i) ?: continue
            if (candidate.optInt("id") == id) item = candidate
        }
        if (item == null) {
            done()
            return
        }
        val check = item.optJSONObject("check") ?: JSONObject()
        val state = state(context)
        val today = dayKey(Calendar.getInstance())
        val title = item.optString("title")
        val body = item.optString("body")
        when (check.optString("type", "none")) {
            "none" -> post(context, item, title, body)
            "workout" -> if (state.optString("workoutDay") != today) {
                post(context, item, title, body)
            }
            "mindful" -> if (state.optString("mindfulDay") != today) {
                post(context, item, title, body)
            }
            "weigh" -> {
                val last = state.optLong("lastWeighMs")
                val days = (System.currentTimeMillis() - last) / 86_400_000L
                if (last == 0L || days >= 5) post(context, item, title, body)
            }
            "meal" -> {
                val logged = state.optString("mealsDay") == today &&
                    (state.optJSONArray("meals")?.let { meals ->
                        (0 until meals.length()).any { meals.optString(it) == check.optString("meal") }
                    } ?: false)
                if (!logged) post(context, item, title, body)
            }
            "water" -> {
                val goal = check.optInt("goal", 2000)
                val drank = if (state.optString("waterDay") == today) state.optInt("waterMl") else 0
                if (drank < goal * check.optDouble("share", 0.5)) {
                    post(
                        context,
                        item,
                        "Time for Water",
                        "${litres(drank)} of ${litres(goal)} so far. A glass now keeps you on track.",
                    )
                }
            }
            "steps" -> {
                readCounter(context) { counter ->
                    steps(context, item, check, state, today, counter)
                    done()
                }
                return
            }
            "sleep" -> sleep(context, item)
        }
        done()
    }

    private fun steps(
        context: Context,
        item: JSONObject,
        check: JSONObject,
        state: JSONObject,
        today: String,
        counter: Long,
    ) {
        val goal = check.optInt("goal", 10000)
        val streak = check.optInt("streak", 0)
        val number = NumberFormat.getIntegerInstance()
        if (state.optString("stepsDay") != today) {
            // Nothing from the app today: only a streak is worth a word.
            if (streak >= 2) {
                post(
                    context,
                    item,
                    "Keep Your $streak-Day Streak",
                    "Reach ${number.format(goal)} steps today to keep it going.",
                )
            }
            return
        }
        var steps = state.optLong("steps")
        val synced = state.optLong("counter", -1)
        if (counter >= 0 && synced >= 0) {
            // A lower reading means the phone restarted: all of it is new.
            steps += if (counter >= synced) counter - synced else counter
        }
        val left = goal - steps
        if (left <= 0) return
        if (steps < goal * 0.4 && streak < 2) return
        val minutes = ((left + 99) / 100).coerceAtLeast(1)
        post(
            context,
            item,
            if (streak >= 2) "Keep Your $streak-Day Streak" else "Almost There",
            "${number.format(left)} steps to go, about $minutes minutes of walking.",
        )
    }

    /** One reading of the step counter, or -1 within two seconds. */
    private fun readCounter(context: Context, then: (Long) -> Unit) {
        val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (sensor == null) {
            then(-1)
            return
        }
        val handler = Handler(Looper.getMainLooper())
        var finished = false
        lateinit var listener: SensorEventListener
        fun finish(value: Long) {
            if (finished) return
            finished = true
            sensors.unregisterListener(listener)
            then(value)
        }
        listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                finish(event.values[0].toLong())
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        try {
            sensors.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_NORMAL, handler)
        } catch (_: Exception) {
            finish(-1)
            return
        }
        handler.postDelayed({ finish(-1) }, 2000)
    }

    /**
     * Last night from the screen history. Not ended yet (the phone still
     * down), it looks again in twenty minutes, until noon.
     */
    private fun sleep(context: Context, item: JSONObject) {
        val now = Calendar.getInstance()
        val events = screenEvents(context, now)
        if (events == null) {
            // No usage access: the plain reminder.
            post(context, item, item.optString("title"), item.optString("body"))
            return
        }
        val night = SleepFromPhone.estimate(events, now.timeInMillis)
        if (night == null) {
            if (now.get(Calendar.HOUR_OF_DAY) < 12) {
                val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                set(context, alarms, item.optInt("id"), now.timeInMillis + 20 * 60_000L)
            }
            return
        }
        val minutes = night.asleepMinutes
        val time = java.text.DateFormat.getTimeInstance(java.text.DateFormat.SHORT)
        post(
            context,
            item,
            "Good Morning",
            "You slept ${minutes / 60} hr ${minutes % 60} min, " +
                "${time.format(night.start)}–${time.format(night.end)}. Tap to check or edit.",
        )
    }

    private fun screenEvents(context: Context, now: Calendar): List<Pair<Long, Int>>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
        val usage = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val from = (now.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.HOUR_OF_DAY, -7)
        }.timeInMillis
        val out = ArrayList<Pair<Long, Int>>()
        try {
            val events = usage.queryEvents(from, now.timeInMillis)
            val event = UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val type = when (event.eventType) {
                    UsageEvents.Event.SCREEN_INTERACTIVE -> SleepFromPhone.SCREEN_ON
                    UsageEvents.Event.SCREEN_NON_INTERACTIVE -> SleepFromPhone.SCREEN_OFF
                    UsageEvents.Event.KEYGUARD_HIDDEN -> SleepFromPhone.UNLOCK
                    UsageEvents.Event.KEYGUARD_SHOWN -> SleepFromPhone.LOCK
                    else -> continue
                }
                out.add(event.timeStamp to type)
            }
        } catch (_: Exception) {
            return null
        }
        // Without usage access the history is simply empty.
        return if (out.isEmpty()) null else out
    }

    private fun litres(ml: Int): String = String.format("%.1f L", ml / 1000.0)

    private fun dayKey(c: Calendar): String = String.format(
        "%04d-%02d-%02d",
        c.get(Calendar.YEAR),
        c.get(Calendar.MONTH) + 1,
        c.get(Calendar.DAY_OF_MONTH),
    )

    private fun ensureChannel(manager: NotificationManager, id: String, name: String) {
        if (manager.getNotificationChannelGroup(GROUP) == null) {
            manager.createNotificationChannelGroup(NotificationChannelGroup(GROUP, "Reminders"))
        }
        if (manager.getNotificationChannel(id) != null) return
        manager.createNotificationChannel(
            NotificationChannel(id, name, NotificationManager.IMPORTANCE_DEFAULT).apply {
                group = GROUP
            },
        )
    }

    private fun post(context: Context, item: JSONObject, title: String, body: String) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (!manager.areNotificationsEnabled()) return
        val channelId = "reminder_${item.optString("kind")}"
        ensureChannel(manager, channelId, item.optString("channel", "Reminders"))
        val id = item.optInt("id")
        val open = PendingIntent.getActivity(
            context,
            id,
            Intent(context, MainActivity::class.java)
                .setAction("com.halo.halo.OPEN_$id")
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                .putExtra(EXTRA_ROUTE, item.optString("route")),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = Notification.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_stat_halo)
            .setColor(ACCENT)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(open)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_REMINDER)
            .build()
        // One at a time per kind: a newer one replaces the last.
        manager.notify("reminder_${item.optString("kind")}".hashCode(), notification)
    }
}

/** The alarms, and putting them back after a restart or a clock change. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Reminders.ACTION_FIRE -> {
                val id = intent.getIntExtra(Reminders.EXTRA_ID, -1)
                val pending = goAsync()
                try {
                    Reminders.fire(context.applicationContext, id) { pending.finish() }
                } catch (_: Exception) {
                    pending.finish()
                }
            }
            else -> Reminders.scheduleAll(context.applicationContext)
        }
    }
}

/**
 * Last night from when the phone was used, as the app works it out
 * (`PhoneUseSleep` in Dart): the longest stretch of the night with the phone
 * unused, joined across uses of five minutes or less.
 */
object SleepFromPhone {
    const val SCREEN_ON = 0
    const val SCREEN_OFF = 1
    const val UNLOCK = 2
    const val LOCK = 3

    private const val BRIEF = 5 * 60_000L
    private const val MINIMUM = 3 * 3_600_000L

    class Night(val start: Long, val end: Long, val awake: Long) {
        val asleepMinutes: Int get() = ((end - start - awake) / 60_000L).toInt()
    }

    fun estimate(events: List<Pair<Long, Int>>, now: Long): Night? {
        val morning = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val from = (morning.clone() as Calendar).apply { add(Calendar.HOUR_OF_DAY, -6) }.timeInMillis
        val cap = (morning.clone() as Calendar).apply { add(Calendar.HOUR_OF_DAY, 15) }.timeInMillis
        val to = minOf(now, cap)
        if (to <= from) return null

        val sorted = events.sortedBy { it.first }
        val locks = sorted.any { it.second == UNLOCK }
        val uses = ArrayList<Pair<Long, Long>>()
        var since: Long? = null
        val first = sorted.firstOrNull { it.first >= from }
        if (first != null && (first.second == SCREEN_OFF || first.second == LOCK)) since = from
        for ((time, type) in sorted) {
            if (time < from || time > to) continue
            val begins = if (locks) type == UNLOCK else type == SCREEN_ON
            val ends = type == SCREEN_OFF || type == LOCK
            if (begins && since == null) {
                since = time
            } else if (ends && since != null) {
                uses.add(since to time)
                since = null
            }
        }
        since?.let { uses.add(it to to) }

        val gaps = ArrayList<Pair<Long, Long>>()
        var cursor = from
        for ((a, b) in uses) {
            if (a > cursor) gaps.add(cursor to a)
            if (b > cursor) cursor = b
        }
        if (uses.isEmpty() || (to <= cursor && gaps.isEmpty())) return null

        var best: Night? = null
        var i = 0
        while (i < gaps.size) {
            val start = gaps[i].first
            var end = gaps[i].second
            var quiet = end - start
            var awake = 0L
            var j = i + 1
            while (j < gaps.size && gaps[j].first - end <= BRIEF) {
                awake += gaps[j].first - end
                end = gaps[j].second
                quiet += gaps[j].second - gaps[j].first
                j++
            }
            val measurable = start > from
            if (measurable && quiet >= MINIMUM &&
                (best == null || quiet > (best.end - best.start - best.awake))
            ) {
                best = Night(start, end, awake)
            }
            i = j
        }

        // A night is mostly at night: its middle between 21:00 and 11:00.
        best?.let {
            val middle = Calendar.getInstance().apply { timeInMillis = it.start + (it.end - it.start) / 2 }
            val hour = middle.get(Calendar.HOUR_OF_DAY) + middle.get(Calendar.MINUTE) / 60.0
            if (hour > 11 && hour < 21) return null
        }
        return best
    }
}
