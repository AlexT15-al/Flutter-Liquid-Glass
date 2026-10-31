package com.halo.halo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Pause and Resume, pressed on the notification, handed to the workout in
 * Dart, which then updates the notification itself.
 */
class WorkoutActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = when (intent.action) {
            WorkoutNotification.ACTION_PAUSE -> "pause"
            WorkoutNotification.ACTION_RESUME -> "resume"
            else -> return
        }
        LiveActivityChannel.send("action", action)
    }
}
