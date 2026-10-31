package com.halo.halo

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import kotlin.math.sqrt

/**
 * Feels the night through the mattress.
 *
 * The phone lies on the bed near the pillow. The accelerometer is read ten
 * times a second; gravity is filtered out, and any second in which what is
 * left rises above a small threshold counts as a moment of movement. Each
 * minute's count (0 to 60) goes to Dart, which stores it and, in the
 * morning, works out the night from it.
 *
 * A foreground service of type health with a quiet notification, holding a
 * partial wake lock so the CPU keeps reading the sensor with the screen off.
 */
class SleepService : Service(), SensorEventListener {
    private var sensors: SensorManager? = null
    private var wakeLock: PowerManager.WakeLock? = null

    private var startMs = 0L
    private var minute = -1
    private var movingSeconds = 0
    private var lastSecond = -1L
    private var secondMoved = false

    private val gravity = FloatArray(3)
    private var primed = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopTracking()
            return START_NOT_STICKY
        }
        startMs = intent?.getLongExtra(EXTRA_START_MS, System.currentTimeMillis())
            ?: System.currentTimeMillis()
        val notification = notification(this)
        try {
            val health = Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
            when {
                health && granted(Manifest.permission.ACTIVITY_RECOGNITION) ->
                    startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
                !health -> startForeground(ID, notification)
                else -> throw IllegalStateException("Physical activity is not allowed.")
            }
        } catch (_: Exception) {
            // Tracks only while the app stays open; Dart is told nothing
            // different, the night simply may have gaps.
        }
        startTracking()
        running = true
        return START_NOT_STICKY
    }

    private fun startTracking() {
        if (sensors != null) return
        val manager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val accelerometer = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return
        manager.registerListener(this, accelerometer, SAMPLING_US)
        sensors = manager
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "halo:sleep").apply {
            setReferenceCounted(false)
            acquire(14 * 60 * 60 * 1000L)
        }
    }

    private fun stopTracking() {
        sensors?.unregisterListener(this)
        sensors = null
        // The minute in progress still counts.
        if (minute >= 0) SleepChannel.emit(minute, movingSeconds + if (secondMoved) 1 else 0)
        minute = -1
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        running = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onSensorChanged(event: SensorEvent) {
        val now = System.currentTimeMillis()
        val v = event.values
        if (!primed) {
            v.copyInto(gravity, endIndex = 3)
            primed = true
            return
        }
        // Gravity follows slowly; what moves faster than it is the bed.
        var sum = 0f
        for (i in 0..2) {
            gravity[i] = ALPHA * gravity[i] + (1 - ALPHA) * v[i]
            val linear = v[i] - gravity[i]
            sum += linear * linear
        }
        val moved = sqrt(sum) > THRESHOLD

        val second = (now - startMs) / 1000
        if (second != lastSecond) {
            if (secondMoved) movingSeconds++
            secondMoved = false
            lastSecond = second
        }
        if (moved) secondMoved = true

        val m = ((now - startMs) / 60_000).toInt()
        if (m != minute) {
            if (minute >= 0) SleepChannel.emit(minute, movingSeconds)
            minute = m
            movingSeconds = 0
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        sensors?.unregisterListener(this)
        sensors = null
        wakeLock?.let { if (it.isHeld) it.release() }
        running = false
        super.onDestroy()
    }

    private fun granted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    companion object {
        const val ACTION_STOP = "com.halo.halo.STOP_SLEEP"
        const val ACTION_OPEN = "com.halo.halo.OPEN_SLEEP"
        const val EXTRA_START_MS = "startMs"
        private const val ID = 7302
        private const val CHANNEL_ID = "sleep_tracking"
        private const val SAMPLING_US = 100_000
        private const val ALPHA = 0.9f

        /** m/s² left after gravity: above breathing, below a turn over. */
        private const val THRESHOLD = 0.12f

        @Volatile
        var running = false
            private set

        private fun notification(context: Context): Notification {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val manager = context.getSystemService(NotificationManager::class.java)
                if (manager?.getNotificationChannel(CHANNEL_ID) == null) {
                    // Minimum: no icon in the status bar, nothing on the lock
                    // screen to light up the room.
                    manager?.createNotificationChannel(
                        NotificationChannel(
                            CHANNEL_ID,
                            "Sleep tracking",
                            NotificationManager.IMPORTANCE_MIN,
                        ).apply { setShowBadge(false) },
                    )
                }
            }
            val open = PendingIntent.getActivity(
                context,
                3,
                Intent(context, MainActivity::class.java)
                    .setAction(ACTION_OPEN)
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }
            return builder
                .setSmallIcon(R.drawable.ic_stat_halo)
                .setContentTitle("Tracking your sleep")
                .setContentText("Good night. Leave the phone on the bed.")
                .setOngoing(true)
                .setShowWhen(false)
                .setContentIntent(open)
                .build()
        }
    }
}
