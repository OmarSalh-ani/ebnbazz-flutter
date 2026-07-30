package com.alsalhani.ebnbazz

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import kotlin.math.max

class StudentPhotoPickerHandler(
    private val activity: MainActivity,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.alsalhani.ebnbazz/student_photo_picker"
        private const val MAX_DIMENSION = 1024
        private const val JPEG_QUALITY = 85
    }

    private var pendingResult: MethodChannel.Result? = null
    private var cameraOutputUri: Uri? = null

    private val galleryLauncher: ActivityResultLauncher<PickVisualMediaRequest> =
        activity.registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
            deliverProcessedPath(uri)
        }

    private val legacyGalleryLauncher: ActivityResultLauncher<String> =
        activity.registerForActivityResult(ActivityResultContracts.GetContent()) { uri ->
            deliverProcessedPath(uri)
        }

    private val cameraLauncher: ActivityResultLauncher<Uri> =
        activity.registerForActivityResult(ActivityResultContracts.TakePicture()) { success ->
            val uri = cameraOutputUri
            cameraOutputUri = null
            if (success && uri != null) {
                deliverProcessedPath(uri)
            } else {
                finishWithError("cancelled", "تم إلغاء التقاط الصورة")
            }
        }

    private val cameraPermissionLauncher: ActivityResultLauncher<String> =
        activity.registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            if (granted) {
                launchCameraCapture()
            } else {
                finishWithError("permission_denied", "يرجى السماح باستخدام الكاميرا")
            }
        }

    fun attachTo(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "عملية اختيار صورة قيد التنفيذ", null)
            return
        }

        pendingResult = result
        when (call.method) {
            "pickFromGallery" -> launchGalleryPicker()
            "takePhoto" -> launchCameraFlow()
            else -> {
                pendingResult = null
                result.notImplemented()
            }
        }
    }

    private fun launchGalleryPicker() {
        if (ActivityResultContracts.PickVisualMedia.isPhotoPickerAvailable(activity)) {
            galleryLauncher.launch(
                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly),
            )
        } else {
            legacyGalleryLauncher.launch("image/*")
        }
    }

    private fun launchCameraFlow() {
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA)
            == PackageManager.PERMISSION_GRANTED
        ) {
            launchCameraCapture()
        } else {
            cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    private fun launchCameraCapture() {
        try {
            val photoFile = createTempPhotoFile()
            val uri = FileProvider.getUriForFile(
                activity,
                "${activity.packageName}.fileprovider",
                photoFile,
            )
            cameraOutputUri = uri
            cameraLauncher.launch(uri)
        } catch (e: Exception) {
            finishWithError("camera_error", "تعذر فتح الكاميرا")
        }
    }

    private fun deliverProcessedPath(uri: Uri?) {
        if (uri == null) {
            finishWithNull()
            return
        }

        try {
            val path = processAndSave(uri)
            if (path == null) {
                finishWithError("processing_failed", "تعذر معالجة الصورة")
            } else {
                finishWithPath(path)
            }
        } catch (e: Exception) {
            finishWithError("processing_failed", "تعذر معالجة الصورة")
        }
    }

    private fun processAndSave(source: Uri): String? {
        val inputStream = activity.contentResolver.openInputStream(source) ?: return null
        inputStream.use { stream ->
            val original = BitmapFactory.decodeStream(stream) ?: return null
            val scaled = scaleBitmap(original)
            if (scaled !== original) {
                original.recycle()
            }

            val output = createTempPhotoFile()
            FileOutputStream(output).use { out ->
                scaled.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, out)
            }
            scaled.recycle()
            return output.absolutePath
        }
    }

    private fun scaleBitmap(source: Bitmap): Bitmap {
        val width = source.width
        val height = source.height
        val largestSide = max(width, height)
        if (largestSide <= MAX_DIMENSION) {
            return source
        }

        val scale = MAX_DIMENSION.toFloat() / largestSide.toFloat()
        val targetWidth = (width * scale).toInt().coerceAtLeast(1)
        val targetHeight = (height * scale).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(source, targetWidth, targetHeight, true)
    }

    private fun createTempPhotoFile(): File {
        val directory = File(activity.cacheDir, "student_photos").apply { mkdirs() }
        return File(directory, "photo_${System.currentTimeMillis()}.jpg")
    }

    private fun finishWithPath(path: String) {
        pendingResult?.success(mapOf("path" to path))
        pendingResult = null
    }

    private fun finishWithNull() {
        pendingResult?.success(null)
        pendingResult = null
    }

    private fun finishWithError(code: String, message: String) {
        pendingResult?.error(code, message, null)
        pendingResult = null
    }
}
