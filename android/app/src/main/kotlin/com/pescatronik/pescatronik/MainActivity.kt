package com.pescatronik.pescatronik

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.OpenableColumns
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "pescatronik/gallery_picker"
    private val pickImageRequestCode = 8421
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickMiuiImage" -> pickMiuiImage(result)
                "pickAndroidImage" -> pickAndroidImage(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pickMiuiImage(result: MethodChannel.Result) {
        if (!preparePicker(result)) return
        val miuiGalleryIntent = Intent(
            Intent.ACTION_PICK,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        ).apply {
            type = "image/*"
            component = ComponentName(
                "com.miui.gallery",
                "com.miui.gallery.picker.PickGalleryActivity"
            )
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/jpeg", "image/png", "image/webp"))
        }
        try {
            startActivityForResult(miuiGalleryIntent, pickImageRequestCode)
        } catch (error: Exception) {
            pendingResult = null
            result.error(
                "miui_gallery_unavailable",
                "No se pudo abrir la Galería de Xiaomi/POCO.",
                null
            )
        }
    }

    private fun pickAndroidImage(result: MethodChannel.Result) {
        if (!preparePicker(result)) return
        val fallbackIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "image/*"
            addCategory(Intent.CATEGORY_OPENABLE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/jpeg", "image/png", "image/webp"))
        }
        try {
            startActivityForResult(Intent.createChooser(fallbackIntent, "Elegir foto"), pickImageRequestCode)
        } catch (error: Exception) {
            pendingResult = null
            result.error("picker_unavailable", "No hay ninguna galería disponible.", null)
        }
    }

    private fun preparePicker(result: MethodChannel.Result): Boolean {
        if (pendingResult != null) {
            result.error("picker_busy", "Ya hay un selector de fotos abierto.", null)
            return false
        }
        pendingResult = result
        return true
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickImageRequestCode) return

        val result = pendingResult
        pendingResult = null
        if (result == null) return

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return
        }

        try {
            result.success(copyUriToCache(uri))
        } catch (error: Exception) {
            result.error("copy_failed", "No se pudo copiar la foto seleccionada.", null)
        }
    }

    private fun copyUriToCache(uri: Uri): String {
        val compressed = compressedImageToCache(uri)
        if (compressed != null) return compressed.absolutePath

        val extension = extensionFor(uri)
        val destination = File(
            cacheDir,
            "pescatronik_picker_${System.currentTimeMillis()}$extension"
        )
        contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "No se pudo abrir la imagen." }
            FileOutputStream(destination).use { output ->
                input.copyTo(output)
            }
        }
        return destination.absolutePath
    }

    private fun compressedImageToCache(uri: Uri): File? {
        val bounds = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        contentResolver.openInputStream(uri).use { input ->
            if (input == null) return null
            BitmapFactory.decodeStream(input, null, bounds)
        }
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        val options = BitmapFactory.Options().apply {
            inSampleSize = sampleSizeFor(bounds.outWidth, bounds.outHeight)
        }
        val bitmap = contentResolver.openInputStream(uri).use { input ->
            if (input == null) return null
            BitmapFactory.decodeStream(input, null, options)
        } ?: return null

        val resized = resizeIfNeeded(bitmap, 1920)
        if (resized != bitmap) bitmap.recycle()

        val destination = File(
            cacheDir,
            "pescatronik_picker_${System.currentTimeMillis()}.jpg"
        )
        FileOutputStream(destination).use { output ->
            resized.compress(Bitmap.CompressFormat.JPEG, 85, output)
        }
        resized.recycle()
        return destination
    }

    private fun sampleSizeFor(width: Int, height: Int): Int {
        var sampleSize = 1
        var halfWidth = width / 2
        var halfHeight = height / 2
        while (halfWidth / sampleSize >= 1920 || halfHeight / sampleSize >= 1920) {
            sampleSize *= 2
        }
        return sampleSize
    }

    private fun resizeIfNeeded(bitmap: Bitmap, maxSide: Int): Bitmap {
        val largestSide = maxOf(bitmap.width, bitmap.height)
        if (largestSide <= maxSide) return bitmap
        val scale = maxSide.toFloat() / largestSide.toFloat()
        val width = (bitmap.width * scale).toInt().coerceAtLeast(1)
        val height = (bitmap.height * scale).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(bitmap, width, height, true)
    }

    private fun extensionFor(uri: Uri): String {
        val name = contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) cursor.getString(index) else null
        }
        val extension = name
            ?.substringAfterLast('.', "")
            ?.lowercase()
            ?.takeIf { it in setOf("jpg", "jpeg", "png", "webp") }
        return if (extension == null) ".jpg" else ".$extension"
    }
}
