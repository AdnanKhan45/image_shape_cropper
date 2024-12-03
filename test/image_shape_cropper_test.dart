// import 'package:flutter_test/flutter_test.dart';
// import 'package:image_shape_cropper/image_shape_cropper.dart';
// import 'package:image_shape_cropper/image_shape_cropper_platform_interface.dart';
// import 'package:image_shape_cropper/image_shape_cropper_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockImageShapeCropperPlatform
//     with MockPlatformInterfaceMixin
//     implements ImageShapeCropperPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final ImageShapeCropperPlatform initialPlatform = ImageShapeCropperPlatform.instance;
//
//   test('$MethodChannelImageShapeCropper is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelImageShapeCropper>());
//   });
//
//   test('getPlatformVersion', () async {
//     ImageShapeCropper imageShapeCropperPlugin = ImageShapeCropper();
//     MockImageShapeCropperPlatform fakePlatform = MockImageShapeCropperPlatform();
//     ImageShapeCropperPlatform.instance = fakePlatform;
//
//     expect(await imageShapeCropperPlugin.getPlatformVersion(), '42');
//   });
// }
