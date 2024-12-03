import 'dart:typed_data';
import 'image_shape_cropper_platform_interface.dart';

class ImageShapeCropper {
  /// Crops the image into an oval shape with the specified angle.
  ///
  /// Returns the cropped image as bytes.
  Future<Uint8List?> cropOval({
    required String sourcePath,
    double angle = 0.0,
    double? width,
    double? height,
    double? scale,
    String? compressFormat,
    int? compressQuality
  }) {
    return ImageShapeCropperPlatform.instance.cropOval(
      sourcePath: sourcePath,
      angle: angle,
      width: width,
      height: height,
      compressFormat: compressFormat,
      compressQuality: compressQuality,
      scale: scale,
    );
  }
}
