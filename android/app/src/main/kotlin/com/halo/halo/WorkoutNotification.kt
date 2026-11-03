package com.halo.halo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle

/**
 * What the live workout notification shows, as sent from Dart.
 */
data class WorkoutState(
    val title: String,
    val elapsedMs: Long,
    val clock: String,
    val paused: Boolean,
    val energy: String,
    val distance: String?,
    val pace: String?,
    val progress: Double?,
    val goal: String?,
    val gps: Boolean,
    /** Live Activity turned off: only what recording a route requires. */
    val quiet: Boolean,
) {
    /** Distance, energy and pace on one line: the notification's text. */
    val metrics: String
        get() = listOfNotNull(distance, energy, pace).joinToString(" · ")

    fun toBundle(): Bundle = Bundle().apply {
        putString("title", title)
        putLong("elapsedMs", elapsedMs)
        putString("clock", clock)
        putBoolean("paused", paused)
        putString("energy", energy)
        putString("distance", distance)
        putString("pace", pace)
        if (progress != null) putDouble("progress", progress)
        putString("goal", goal)
        putBoolean("gps", gps)
        putBoolean("quiet", quiet)
    }

    companion object {
        fun fromMap(map: Map<*, *>): WorkoutState = WorkoutState(
            title = map["title"] as? String ?: "Workout",
            elapsedMs = (map["elapsedMs"] as? Number)?.toLong() ?: 0L,
            clock = map["clock"] as? String ?: "",
            paused = map["paused"] as? Boolean ?: false,
            energy = map["energy"] as? String ?: "",
            distance = map["distance"] as? String,
            pace = map["pace"] as? String,
            progress = (map["progress"] as? Number)?.toDouble(),
            goal = map["goal"] as? String,
            gps = map["gps"] as? Boolean ?: false,
            quiet = map["quiet"] as? Boolean ?: false,
        )

        fun fromBundle(bundle: Bundle?): WorkoutState? {
            if (bundle == null || !bundle.containsKey("title")) return null
            return WorkoutState(
                title = bundle.getString("title") ?: "Workout",
                elapsedMs = bundle.getLong("elapsedMs"),
                clock = bundle.getString("clock") ?: "",
                paused = bundle.getBoolean("paused"),
                energy = bundle.getString("energy") ?: "",
                distance = bundle.getString("distance"),
                pace = bundle.getString("pace"),
                progress = if (bundle.containsKey("progress")) bundle.getDouble("progress") else null,
                goal = bundle.getString("goal"),
                gps = bundle.getBoolean("gps"),
                quiet = bundle.getBoolean("quiet"),
            )
        }
    }
}

/**
 * The workout in progress as an ongoing notification that asks to be a Live
 * Update.
 *
 * On Android 16 a promoted notification becomes a chip in the status bar and
 * a card at the top of the lock screen and shade, and One UI 8 shows it in
 * the Now Bar. It qualifies only while it keeps to the rules: ongoing, with a
 * title, a progress style, not colorized, no custom views. Samsung asks for
 * more: the app declares it in the manifest
 * (`com.samsung.android.support.ongoing_activity`), the channel is of default
 * importance, and the notification is posted as well as started with the
 * service. Older versions show it as an ordinary ongoing notification.
 *
 * The time runs on its own: the notification is a chronometer from the
 * moment the workout would have started had it never paused, so nothing has
 * to be posted every second.
 */
object WorkoutNotification {
    const val ID = 7301

    /**
     * Default importance, silent: what Samsung's Now Bar takes a Live Update
     * from (low importance stays a notification). A channel's importance is
     * fixed once made, so a new one replaces the first.
     */
    private const val CHANNEL_ID = "workout_live_v2"
    private val OLD_CHANNELS = listOf("workout_live")

    const val ACTION_OPEN = "com.halo.halo.OPEN_WORKOUT"
    const val ACTION_PAUSE = "com.halo.halo.PAUSE_WORKOUT"
    const val ACTION_RESUME = "com.halo.halo.RESUME_WORKOUT"

    /** Halo's accent, as the light theme draws it: legible on either shade. */
    private const val ACCENT = 0xFF4A8F00.toInt()

    private const val EXTRA_REQUEST_PROMOTED_ONGOING = "android.requestPromotedOngoing"

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        for (old in OLD_CHANNELS) {
            try {
                manager.deleteNotificationChannel(old)
            } catch (_: Exception) {
            }
        }
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        // Default importance, which the Now Bar asks for, but silent: it
        // updates every few seconds and must never make a sound or buzz.
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Workout in progress",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "The time and numbers of the workout you are doing."
            setShowBadge(false)
            setSound(null, null)
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    fun build(context: Context, state: WorkoutState): Notification {
        ensureChannel(context)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        if (state.quiet) {
            // Android shows a notification for every foreground service; with
            // Live Activity off this is all it says.
            return builder
                .setSmallIcon(R.drawable.ic_stat_halo)
                .setContentTitle(state.title)
                .setContentText("Recording your route")
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(false)
                .setCategory("workout")
                .setColor(ACCENT)
                .setContentIntent(activityIntent(context))
                .build()
        }

        builder
            .setSmallIcon(R.drawable.ic_stat_halo)
            .setContentTitle(state.title)
            .setContentText(
                if (state.paused) "Paused · ${state.metrics}" else state.metrics,
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory("workout")
            .setColor(ACCENT)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setContentIntent(activityIntent(context))
            .addAction(pauseAction(context, state.paused))

        if (state.paused) {
            builder.setShowWhen(false).setUsesChronometer(false).setSubText(state.clock)
        } else {
            builder
                .setWhen(System.currentTimeMillis() - state.elapsedMs)
                .setShowWhen(true)
                .setUsesChronometer(true)
        }

        // Always a progress style on Android 16: the Now Bar shows Live
        // Updates drawn with one. The goal, the interval, or (with an open
        // goal) the day's Exercise goal, sent from Dart.
        val progress = state.progress
        val value = ((progress ?: 0.0).coerceIn(0.0, 1.0) * 1000).toInt()
        if (Build.VERSION.SDK_INT >= 36) {
            builder.setStyle(
                Notification.ProgressStyle()
                    .setProgressSegments(
                        listOf(Notification.ProgressStyle.Segment(1000).setColor(ACCENT)),
                    )
                    .setProgress(value)
                    .setProgressTrackerIcon(
                        Icon.createWithResource(context, R.drawable.ic_stat_halo),
                    ),
            )
        } else if (progress != null) {
            builder.setProgress(1000, value, false)
        }
        state.goal?.let {
            builder.setSubText(if (state.paused) "${state.clock} · $it" else it)
        }

        requestPromotion(builder, state)
        return builder.build()
    }

    /**
     * Asks Android 16 to promote it. Through the extra and, where the build has
     * them, the builder methods, called by name so the app still compiles and
     * runs against SDKs from before they existed.
     */
    private fun requestPromotion(builder: Notification.Builder, state: WorkoutState) {
        if (Build.VERSION.SDK_INT < 36) return
        builder.addExtras(Bundle().apply { putBoolean(EXTRA_REQUEST_PROMOTED_ONGOING, true) })
        try {
            builder.javaClass
                .getMethod("setRequestPromotedOngoing", Boolean::class.javaPrimitiveType)
                .invoke(builder, true)
        } catch (_: Exception) {
        }
        // The chip in the status bar and the Now Bar's short line: the word
        // while paused, the distance while it grows; otherwise the running
        // time, from the chronometer.
        val chip = if (state.paused) "Paused" else state.distance
        if (chip != null) {
            try {
                builder.javaClass
                    .getMethod("setShortCriticalText", String::class.java)
                    .invoke(builder, chip)
            } catch (_: Exception) {
            }
        }
    }

    private fun activityIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(ACTION_OPEN)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun pauseAction(context: Context, paused: Boolean): Notification.Action {
        val action = if (paused) ACTION_RESUME else ACTION_PAUSE
        val intent = Intent(context, WorkoutActionReceiver::class.java).setAction(action)
        val pending = PendingIntent.getBroadcast(
            context,
            if (paused) 2 else 1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val icon = Icon.createWithResource(
            context,
            if (paused) android.R.drawable.ic_media_play else android.R.drawable.ic_media_pause,
        )
        return Notification.Action.Builder(icon, if (paused) "Resume" else "Pause", pending)
            .build()
    }
}
