package com.halo.halo

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Runtime permissions, answered by the activity itself.
 *
 * The app needs very little here (Physical activity for the step counter, and
 * later notifications), so a dozen lines on the `halo/permissions` channel
 * replace a whole plugin and the compile-SDK requirements that came with it.
 *
 * Statuses are the three the UI acts on:
 * - `granted`
 * - `denied`: can still be asked
 * - `permanentlyDenied`: refused twice; only Settings can change it
 */
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
        LiveActivityChannel.attach(this, flutterEngine.dartExecutor.binaryMessenger)
        SleepChannel.attach(this, flutterEngine.dartExecutor.binaryMessenger)
        ScreenHistoryChannel.attach(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    /** A tap on the live workout notification: bring the workout up. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        when (intent.action) {
            WorkoutNotification.ACTION_OPEN -> LiveActivityChannel.send("open", null)
            SleepService.ACTION_OPEN -> SleepChannel.open()
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> {
                val permission = call.argument<String>("permission")
                if (permission == null) {
                    result.error("bad_args", "Missing permission.", null)
                } else {
                    result.success(status(permission))
                }
            }
            "request" -> {
                val permission = call.argument<String>("permission")
                if (permission == null) {
                    result.error("bad_args", "Missing permission.", null)
                } else {
                    request(permission, result)
                }
            }
            "openSettings" -> {
                openSettings()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Below the API level that introduced a permission, it is granted at install. */
    private fun isRuntimePermission(permission: String): Boolean = when (permission) {
        "android.permission.ACTIVITY_RECOGNITION" ->
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
        "android.permission.POST_NOTIFICATIONS" ->
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
        else -> true
    }

    private fun status(permission: String): String {
        if (!isRuntimePermission(permission)) return "granted"
        if (checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            return "granted"
        }
        // Android reports "no rationale" both before the first request and after
        // a permanent refusal, so whether it was ever asked tells the two apart.
        val asked = getPreferences(MODE_PRIVATE).getBoolean(ASKED_PREFIX + permission, false)
        return if (asked && !shouldShowRequestPermissionRationale(permission)) {
            "permanentlyDenied"
        } else {
            "denied"
        }
    }

    private fun request(permission: String, result: MethodChannel.Result) {
        val current = status(permission)
        if (current != "denied") {
            result.success(current)
            return
        }
        if (pendingResult != null) {
            result.error("busy", "A permission request is already running.", null)
            return
        }
        pendingResult = result
        getPreferences(MODE_PRIVATE).edit().putBoolean(ASKED_PREFIX + permission, true).apply()
        requestPermissions(arrayOf(permission), REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_CODE) return
        val result = pendingResult ?: return
        pendingResult = null
        val permission = permissions.firstOrNull()
        result.success(if (permission == null) "denied" else status(permission))
    }

    private fun openSettings() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null),
        )
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private companion object {
        const val CHANNEL = "halo/permissions"
        const val REQUEST_CODE = 4127
        const val ASKED_PREFIX = "asked:"
    }
}
