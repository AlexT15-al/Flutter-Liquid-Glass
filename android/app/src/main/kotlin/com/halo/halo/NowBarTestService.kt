package com.halo.halo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Now Bar test 5 and 6: posted from a foreground service, as the user's
 * navigation app posts the notification that reaches the Now Bar.
 *
 * 5. Its code, line for line: NotificationCompat 1.17.
 * 6. The same through the platform builder (test 1), from the service.
 */
class NowBarTestService : Service() {
    companion object {
        const val ID = 7398
        const val CHANNEL_ID = "nowbar_test"
        const val EXTRA_VARIANT = "variant"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val variant = intent?.getIntExtra(EXTRA_VARIANT, 0) ?: 0
        if (variant == 0) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        ensureChannel()
        val notification = if (variant == 5) {
            compat()
        } else {
            WorkoutNotification.test(this, 1)
        }
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
                } catch (_: Exception) {
                    // Location not granted: as a health service instead.
                    startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
                }
            } else {
                startForeground(ID, notification)
            }
            nm.notify(ID, notification)
        } catch (_: Exception) {
            nm.notify(ID, notification)
        }
        return START_NOT_STICKY
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Now Bar test",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            },
        )
    }

    /** The navigation app's notification, with a test's words. */
    private fun compat(): android.app.Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val progress = 40
        val segmentColor = 0xFF4A8F00.toInt()
        val progressStyle = NotificationCompat.ProgressStyle()
            .setProgressSegments(
                listOf(
                    NotificationCompat.ProgressStyle.Segment(progress).setColor(segmentColor),
                    NotificationCompat.ProgressStyle.Segment(100 - progress)
                        .setColor(0xFF3A3A3A.toInt()),
                ),
            )
            .setProgressPoints(
                listOf(
                    NotificationCompat.ProgressStyle.Point(progress).setColor(segmentColor),
                    NotificationCompat.ProgressStyle.Point(100).setColor(segmentColor),
                ),
            )
            .setProgress(progress)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_halo)
            .setContentTitle("Now Bar test 5")
            .setContentText("2.41 km · 186 kcal")
            .setShortCriticalText("2.41 km")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setShowWhen(false)
            .setRequestPromotedOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
            .setStyle(progressStyle)
            .build()
    }
}
