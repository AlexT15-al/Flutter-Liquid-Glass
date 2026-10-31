package com.halo.halo

import android.Manifest
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/**
 * Keeps a workout alive while the phone is in a pocket.
 *
 * A foreground service whose notification is the live workout itself, so
 * there is one notification, not a second one for the service. Of type
 * location when GPS follows the route, which is what lets location updates
 * carry on in the background, and of type health when the step counter is
 * allowed, which keeps the steps coming. A partial wake lock stops the CPU
 * from sleeping between fixes.
 */
class WorkoutService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val state = WorkoutState.fromBundle(intent?.extras)
        if (state == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        val notification = WorkoutNotification.build(this, state)
        val types = foregroundTypes(state.gps)
        try {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && types != 0 ->
                    startForeground(WorkoutNotification.ID, notification, types)
                Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE ->
                    startForeground(WorkoutNotification.ID, notification)
                else -> throw IllegalStateException("No foreground service type is allowed.")
            }
        } catch (_: Exception) {
            // Without a type it may use, the workout still shows; it just is
            // not protected from being stopped in the background.
            getSystemService(NotificationManager::class.java)
                ?.notify(WorkoutNotification.ID, notification)
            stopSelf()
            return START_NOT_STICKY
        }
        if (wakeLock == null) {
            val power = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "halo:workout").apply {
                setReferenceCounted(false)
                // A ceiling, in case the app dies without ending the workout.
                acquire(6 * 60 * 60 * 1000L)
            }
        }
        return START_NOT_STICKY
    }

    private fun foregroundTypes(gps: Boolean): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return 0
        var types = 0
        if (gps && granted(Manifest.permission.ACCESS_FINE_LOCATION)) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            granted(Manifest.permission.ACTIVITY_RECOGNITION)
        ) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
        }
        return types
    }

    private fun granted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    override fun onDestroy() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        super.onDestroy()
    }
}
