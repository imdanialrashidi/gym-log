package com.imdanialrashidi.gymlog

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets

/**
 * System save/open UI for JSON backups (`IO-006`). The app never asks for
 * broad storage permission and never receives a permanent file path: Android's
 * document picker returns a content URI that is used once.
 */
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingAction: PendingAction? = null
    private var pendingContents: String? = null

    private enum class PendingAction { SAVE, OPEN }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                handle(call, result)
            }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Another file operation is already running.", null)
            return
        }
        when (call.method) {
            "saveExport" -> {
                val fileName = call.argument<String>("fileName")
                val contents = call.argument<String>("contents")
                if (fileName.isNullOrBlank() || contents == null) {
                    result.error("bad_args", "A file name and contents are required.", null)
                    return
                }
                pendingResult = result
                pendingAction = PendingAction.SAVE
                pendingContents = contents
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/json"
                    putExtra(Intent.EXTRA_TITLE, fileName)
                }
                startPicker(intent, REQUEST_SAVE, result)
            }
            "pickImport" -> {
                pendingResult = result
                pendingAction = PendingAction.OPEN
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/json"
                    putExtra(
                        Intent.EXTRA_MIME_TYPES,
                        arrayOf("application/json", "text/plain", "application/octet-stream"),
                    )
                }
                startPicker(intent, REQUEST_OPEN, result)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Clears the pending hand-off if the system cannot launch a picker, so a
     * failed launch cannot leave the channel permanently busy.
     */
    private fun startPicker(
        intent: Intent,
        requestCode: Int,
        result: MethodChannel.Result,
    ) {
        try {
            startActivityForResult(intent, requestCode)
        } catch (error: Exception) {
            pendingResult = null
            pendingAction = null
            pendingContents = null
            result.error(
                "unavailable",
                "Could not open the system file picker.",
                error.message,
            )
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_SAVE && requestCode != REQUEST_OPEN) {
            return
        }
        val result = pendingResult ?: return
        val action = pendingAction ?: return
        val contents = pendingContents
        pendingResult = null
        pendingAction = null
        pendingContents = null

        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            if (action == PendingAction.SAVE) {
                result.success(false)
            } else {
                result.success(null)
            }
            return
        }

        when (action) {
            PendingAction.SAVE -> writeExport(result, uri, contents ?: "")
            PendingAction.OPEN -> readImport(result, uri)
        }
    }

    private fun writeExport(
        result: MethodChannel.Result,
        uri: Uri,
        contents: String,
    ) {
        Thread {
            try {
                val stream = contentResolver.openOutputStream(uri, "wt")
                    ?: throw IOException("Could not open the selected file.")
                stream.use {
                    it.write(contents.toByteArray(StandardCharsets.UTF_8))
                    it.flush()
                }
                runOnUiThread { result.success(true) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "write_failed",
                        "Could not write the backup file.",
                        error.message,
                    )
                }
            }
        }.start()
    }

    private fun readImport(result: MethodChannel.Result, uri: Uri) {
        Thread {
            try {
                val input = contentResolver.openInputStream(uri)
                    ?: throw IOException("Could not open the selected file.")
                val bytes = input.use {
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(64 * 1024)
                    var total = 0
                    while (true) {
                        val read = it.read(buffer)
                        if (read < 0) {
                            break
                        }
                        total += read
                        if (total > MAX_BACKUP_BYTES) {
                            throw TooLargeException()
                        }
                        output.write(buffer, 0, read)
                    }
                    output.toByteArray()
                }
                val decoder = StandardCharsets.UTF_8
                    .newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                val text = decoder.decode(ByteBuffer.wrap(bytes)).toString()
                runOnUiThread { result.success(text) }
            } catch (error: TooLargeException) {
                runOnUiThread {
                    result.error("too_large", "The selected file is too large.", null)
                }
            } catch (error: CharacterCodingException) {
                runOnUiThread {
                    result.error(
                        "read_failed",
                        "The selected file is not valid UTF-8 text.",
                        null,
                    )
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "read_failed",
                        "Could not read the selected file.",
                        error.message,
                    )
                }
            }
        }.start()
    }

    private class TooLargeException : Exception()

    companion object {
        private const val CHANNEL = "gym_log/backup"
        private const val REQUEST_SAVE = 0x6701
        private const val REQUEST_OPEN = 0x6702
        private const val MAX_BACKUP_BYTES = 32 * 1024 * 1024
    }
}
