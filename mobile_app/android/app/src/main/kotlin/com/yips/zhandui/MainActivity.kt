package com.yips.zhandui

import android.app.Activity.ScreenCaptureCallback
import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "anonymous_polls/screenshot"
    private var channel: MethodChannel? = null

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private val screenCaptureCallback = ScreenCaptureCallback {
        channel?.invokeMethod("onScreenshot", null)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "saveImageToGallery") {
                val bytes = call.argument<ByteArray>("bytes")
                val name = call.argument<String>("name") ?: "standpoint_${System.currentTimeMillis()}.jpg"
                if (bytes == null) {
                    result.error("NO_BYTES", "Image bytes are required", null)
                    return@setMethodCallHandler
                }
                try {
                    saveImageToGallery(bytes, name)
                    result.success(true)
                } catch (error: Exception) {
                    result.error("SAVE_FAILED", error.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveImageToGallery(bytes: ByteArray, name: String) {
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Standpoint")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
        }
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Cannot create gallery item")
        resolver.openOutputStream(uri)?.use { output ->
            output.write(bytes)
        } ?: throw IllegalStateException("Cannot open gallery output stream")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        }
    }

    override fun onStart() {
        super.onStart()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            registerScreenCaptureCallback(mainExecutor, screenCaptureCallback)
        }
    }

    override fun onStop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            unregisterScreenCaptureCallback(screenCaptureCallback)
        }
        super.onStop()
    }
}
