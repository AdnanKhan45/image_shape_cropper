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
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val compressFormat = call.argument<String>("compressFormat") ?: "png"
        val compressQuality = call.argument<Int>("compressQuality") ?: 100

        Log.d(
          "ImageShapeCropper",
          "cropOval called with sourcePath: $sourcePath, angle: $angle, width: $width, height: $height, compressFormat: $compressFormat, compressQuality: $compressQuality"
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

          // Crop to oval without stretching
          val ovalBitmap = cropOval(rotatedBitmap, width, height)
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

  private fun cropOval(source: Bitmap, desiredWidth: Int?, desiredHeight: Int?): Bitmap {
    val width = desiredWidth ?: source.width
    val height = desiredHeight ?: source.height

    // Calculate the scaling factor to maintain aspect ratio
    val scale: Float
    val scaledWidth: Int
    val scaledHeight: Int

    val sourceWidth = source.width
    val sourceHeight = source.height

    val desiredAspect = width.toFloat() / height.toFloat()
    val sourceAspect = sourceWidth.toFloat() / sourceHeight.toFloat()

    if (sourceAspect > desiredAspect) {
      // Source is wider than desired aspect ratio
      scale = height.toFloat() / sourceHeight.toFloat()
    } else {
      // Source is taller than desired aspect ratio
      scale = width.toFloat() / sourceWidth.toFloat()
    }

    scaledWidth = (sourceWidth * scale).toInt()
    scaledHeight = (sourceHeight * scale).toInt()

    // Scale the bitmap
    val scaledBitmap = Bitmap.createScaledBitmap(source, scaledWidth, scaledHeight, true)

    // Calculate the top-left coordinates for center-cropping
    val left = (scaledWidth - width) / 2
    val top = (scaledHeight - height) / 2

    // Center-crop the bitmap
    val croppedBitmap = Bitmap.createBitmap(scaledBitmap, left, top, width, height)

    // Create a bitmap with transparency
    val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(output)

    val paint = Paint().apply {
      isAntiAlias = true
      isFilterBitmap = true
      isDither = true
    }

    // Draw the oval
    val rect = RectF(0f, 0f, width.toFloat(), height.toFloat())
    canvas.drawOval(rect, paint)

    // Set the blending mode to SRC_IN to keep only the oval area
    paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
    canvas.drawBitmap(croppedBitmap, 0f, 0f, paint)

    return output
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
