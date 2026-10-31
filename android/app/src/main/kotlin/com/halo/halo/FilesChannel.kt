package com.halo.halo

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `halo/files`: the system's own pickers for exporting and importing data.
 *
 * - `export {folder, files}`: the user picks a place, Halo creates a folder
 *   there and writes each file into it. Returns false if cancelled.
 * - `import`: the user picks one or more files; returns name → contents, or
 *   null if cancelled.
 *
 * The Storage Access Framework needs no storage permission: the user's pick
 * is the permission.
 */
class FilesChannel(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var exportFolder: String = "Halo Export"
    private var exportFiles: Map<String, String> = emptyMap()

    fun attach(messenger: BinaryMessenger) {
        MethodChannel(messenger, "halo/files").setMethodCallHandler { call, result ->
            if (pending != null) {
                result.error("busy", "A file picker is already open.", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "export" -> {
                    exportFolder = call.argument<String>("folder") ?: "Halo Export"
                    @Suppress("UNCHECKED_CAST")
                    exportFiles = call.argument<Map<String, String>>("files") ?: emptyMap()
                    pending = result
                    activity.startActivityForResult(
                        Intent(Intent.ACTION_OPEN_DOCUMENT_TREE),
                        REQUEST_EXPORT,
                    )
                }
                "import" -> {
                    pending = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
                        .addCategory(Intent.CATEGORY_OPENABLE)
                        .setType("*/*")
                        .putExtra(
                            Intent.EXTRA_MIME_TYPES,
                            arrayOf(
                                "text/csv",
                                "text/comma-separated-values",
                                "application/csv",
                                "text/plain",
                            ),
                        )
                        .putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    activity.startActivityForResult(intent, REQUEST_IMPORT)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** From the activity's `onActivityResult`; true if it was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_EXPORT && requestCode != REQUEST_IMPORT) return false
        val result = pending ?: return true
        pending = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(if (requestCode == REQUEST_EXPORT) false else null)
            return true
        }
        try {
            if (requestCode == REQUEST_EXPORT) {
                write(data.data!!)
                result.success(true)
            } else {
                result.success(read(data))
            }
        } catch (e: Exception) {
            result.error("io", e.message, null)
        }
        return true
    }

    private fun write(tree: Uri) {
        val resolver = activity.contentResolver
        val parent = DocumentsContract.buildDocumentUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        val folder = DocumentsContract.createDocument(
            resolver,
            parent,
            DocumentsContract.Document.MIME_TYPE_DIR,
            exportFolder,
        ) ?: parent
        for ((name, content) in exportFiles) {
            val file = DocumentsContract.createDocument(resolver, folder, "text/csv", name)
                ?: continue
            resolver.openOutputStream(file)?.use { it.write(content.toByteArray()) }
        }
        exportFiles = emptyMap()
    }

    private fun read(data: Intent): Map<String, String> {
        val uris = buildList {
            val clip = data.clipData
            if (clip != null) {
                for (i in 0 until clip.itemCount) add(clip.getItemAt(i).uri)
            } else {
                data.data?.let { add(it) }
            }
        }
        val resolver = activity.contentResolver
        val out = LinkedHashMap<String, String>()
        for (uri in uris) {
            var name = uri.lastPathSegment ?: "file.csv"
            resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) name = cursor.getString(0) ?: name
                }
            val text = resolver.openInputStream(uri)?.use { it.readBytes().decodeToString() }
            if (text != null) out[name] = text
        }
        return out
    }

    private companion object {
        const val REQUEST_EXPORT = 5101
        const val REQUEST_IMPORT = 5102
    }
}
