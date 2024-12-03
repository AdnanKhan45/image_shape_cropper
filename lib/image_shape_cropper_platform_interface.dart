import 'dart:typed_data';
import 'package:image_shape_cropper/image_shape_cropper_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class ImageShapeCropperPlatform extends PlatformInterface {
  /// Constructs a ImageShapeCropperPlatform.
  ImageShapeCropperPlatform() : super(token: _token);

  static final Object _token = Object();

  static ImageShapeCropperPlatform _instance = MethodChannelImageShapeCropper();

  /// The default instance of [ImageShapeCropperPlatform] to use.
  ///
  /// Defaults to [MethodChannelImageShapeCropper].
  static ImageShapeCropperPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ImageShapeCropperPlatform] when
  /// they register themselves.
  static set instance(ImageShapeCropperPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Crops the image into an oval shape with the specified angle.
  ///
  /// [sourcePath]: The absolute path of the image file.
  /// [angle]: The rotation angle in degrees.
  /// [width]: The width of the output image.
  /// [height]: The height of the output image.
  ///
  /// Returns the cropped image as bytes.
  Future<Uint8List?> cropOval({
    required String sourcePath,
    double angle = 0.0,
    int? width,
    int? height,
    String? compressFormat,
    int? compressQuality
  }) {
    throw UnimplementedError('cropOval() has not been implemented.');
  }
}
