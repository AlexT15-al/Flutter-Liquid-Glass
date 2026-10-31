package com.halo.halo

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `halo/share`: an image to the system share sheet.
 *
 * The picture is saved to Pictures/Halo through MediaStore, which needs no
 * permission from Android 10 on, and shared by its content URI, so no file
 * provider is needed either. The user keeps a copy in their gallery.
 */
class ShareChannel(private val activity: Activity) {
    fun attach(messenger: BinaryMessenger) {
        MethodChannel(messenger, "halo/share").setMethodCallHandler { call, result ->
            if (call.method != "image") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val bytes = call.argument<ByteArray>("png")
            val name = call.argument<String>("name") ?: "Halo"
            val text = call.argument<String>("text")
            if (bytes == null) {
                result.error("bad_args", "Missing image.", null)
                return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                result.error("unsupported", "Sharing images needs Android 10 or later.", null)
                return@setMethodCallHandler
            }
            try {
                val resolver = activity.contentResolver
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, "$name.png")
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(
                        MediaStore.Images.Media.RELATIVE_PATH,
                        "${Environment.DIRECTORY_PICTURES}/Halo",
                    )
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                    ?: throw IllegalStateException("Could not save the image.")
                resolver.openOutputStream(uri)?.use { it.write(bytes) }
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)

                val send = Intent(Intent.ACTION_SEND)
                    .setType("image/png")
                    .putExtra(Intent.EXTRA_STREAM, uri)
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                if (text != null) send.putExtra(Intent.EXTRA_TEXT, text)
                activity.startActivity(Intent.createChooser(send, null))
                result.success(true)
            } catch (e: Exception) {
                result.error("io", e.message, null)
            }
        }
    }
}
