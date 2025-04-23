package com.example.project_management_webview

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ContentValues
import android.provider.MediaStore
import android.os.Build
import android.util.Log
import java.io.OutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "download_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "saveFileToDownloads") {
                val filename = call.argument<String>("filename")!!
                val bytes = call.argument<ByteArray>("bytes")!!
                val resolver = applicationContext.contentResolver

                val contentValues = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, filename)
                    put(MediaStore.Downloads.MIME_TYPE, "application/octet-stream")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }

                val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                val uri = resolver.insert(collection, contentValues)!!

                resolver.openOutputStream(uri)?.use { outputStream ->
                    outputStream.write(bytes)
                }

                contentValues.clear()
                contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, contentValues, null, null)

                result.success("Success")
            } else {
                result.notImplemented()
            }
        }
    }
}
