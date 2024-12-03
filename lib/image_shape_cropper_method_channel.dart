import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_shape_cropper_platform_interface.dart';

/// An implementation of [ImageShapeCropperPlatform] that uses method channels.
class MethodChannelImageShapeCropper extends ImageShapeCropperPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('image_shape_cropper');

  @override
  Future<Uint8List?> cropOval({
    required String sourcePath,
    double angle = 0.0,
    double? width,
    double? height,
    double? scale,
    String? compressFormat,
    int? compressQuality

  }) async {
    final bytes = await methodChannel.invokeMethod<Uint8List>('cropOval', {
      'sourcePath': sourcePath,
      'angle': angle,
      'width': width,
      'height': height,
      'scale': scale,
      'compressFormat': compressFormat,
      'compressQuality': compressQuality,
    });
    return bytes;
  }
}
