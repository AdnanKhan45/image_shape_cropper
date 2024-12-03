package com.example.image_shape_cropper

import android.graphics.*
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import android.util.Log

/** ImageShapeCropperPlugin */
class ImageShapeCropperPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "image_shape_cropper")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    when (call.method) {
      "cropOval" -> {
        val sourcePath = call.argument<String>("sourcePath")
        val angle = call.argument<Double>("angle") ?: 0.0
        val width = call.argument<Double>("width")
        val height = call.argument<Double>("height")
        val scale = call.argument<Double>("scale") ?: 1.0
        val compressFormat = call.argument<String>("compressFormat") ?: "png"
        val compressQuality = call.argument<Int>("compressQuality") ?: 100

        Log.d(
          "ImageShapeCropper",
          "cropOval called with sourcePath: $sourcePath, angle: $angle, width: $width, height: $height, scale: $scale, compressFormat: $compressFormat, compressQuality: $compressQuality"
        )

        if (sourcePath == null) {
          result.error("INVALID_ARGUMENT", "sourcePath is null", null)
          return
        }

        try {
          val bitmap = BitmapFactory.decodeFile(sourcePath)
          if (bitmap == null) {
            Log.e("ImageShapeCropper", "Cannot decode image from path: $sourcePath")
            result.error("INVALID_IMAGE", "Cannot decode image", null)
            return
          }

          // Rotate the bitmap
          val rotatedBitmap = rotateBitmap(bitmap, angle.toFloat())
          Log.d("ImageShapeCropper", "Bitmap rotated by $angle degrees.")

          // Crop to oval with scaling
          val ovalBitmap = cropOval(rotatedBitmap, width, height, scale)
          Log.d("ImageShapeCropper", "Bitmap cropped to oval.")

          // Compress the bitmap
          val byteArrayOutputStream = ByteArrayOutputStream()
          val format = if (compressFormat.equals("png", ignoreCase = true)) {
            Bitmap.CompressFormat.PNG
          } else {
            Bitmap.CompressFormat.JPEG
          }
          ovalBitmap.compress(format, compressQuality, byteArrayOutputStream)
          val bytes = byteArrayOutputStream.toByteArray()

          Log.d("ImageShapeCropper", "Bitmap compressed. Size: ${bytes.size} bytes.")

          result.success(bytes)
        } catch (e: Exception) {
          Log.e("ImageShapeCropper", "Error cropping image: ${e.message}")
          result.error("CROP_FAILED", e.message, null)
        }
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  private fun rotateBitmap(source: Bitmap, angle: Float): Bitmap {
    val matrix = Matrix()
    matrix.postRotate(angle)
    return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
  }

  private fun cropOval(source: Bitmap, desiredWidth: Double?, desiredHeight: Double?, scale: Double): Bitmap {
    val width = desiredWidth ?: source.width.toDouble()
    val height = desiredHeight ?: source.height.toDouble()

    // Ensure scale is at least 1.0
    val effectiveScale = when {
      scale < 1.0 -> 1.0
      scale > 5.0 -> 5.0
      else -> scale
    }

    // Calculate the size of the crop rectangle based on scale
    val cropWidth = (width / effectiveScale).toFloat()
    val cropHeight = (height / effectiveScale).toFloat()

    // Calculate the top-left coordinates for center-cropping
    val left = ((source.width - cropWidth) / 2).toInt()
    val top = ((source.height - cropHeight) / 2).toInt()

    // Ensure crop bounds are within the source bitmap
    val finalCropWidth = if (left < 0) source.width else cropWidth.toInt().coerceAtMost(source.width - left)
    val finalCropHeight = if (top < 0) source.height else cropHeight.toInt().coerceAtMost(source.height - top)

    // Center-crop the bitmap
    val croppedBitmap = Bitmap.createBitmap(source, left, top, finalCropWidth, finalCropHeight)

    // Scale the cropped bitmap back to desired size
    val scaledBitmap = Bitmap.createScaledBitmap(croppedBitmap, width.toInt(), height.toInt(), true)

    // Create a bitmap with transparency
    val output = Bitmap.createBitmap(width.toInt(), height.toInt(), Bitmap.Config.ARGB_8888)
    val canvas = Canvas(output)

    val paint = Paint().apply {
      isAntiAlias = true
      isFilterBitmap = true
      isDither = true
    }

    // Clear the canvas with a transparent color
    canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)

    // Draw the oval path
    val rect = RectF(0f, 0f, width.toFloat(), height.toFloat())
    canvas.drawOval(rect, paint)

    // Set the blending mode to SRC_IN to keep only the oval area
    paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
    canvas.drawBitmap(scaledBitmap, 0f, 0f, paint)

    return output
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
