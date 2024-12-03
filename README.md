# image_shape_cropper

A plugin to crop image in different shapes (oval, circle, square, rect and more)

## Currently supported shapes:

- Oval

## Future supported shapes:

- Circle
- Square
- Rectangle
- Triangle
- Pentagon
- Hexagon
- Octagon
- Star
- Heart
- Diamond

## Usage

```dart
final ImageShapeCropper _cropper = ImageShapeCropper();

final bytes = await _cropper.cropOval(
  sourcePath: pickedFile.path,
  angle: 0, // Rotate any degrees
  width: 150,
  height: 300,
  scale: 1.0, // between 0.0 & 5.0
  compressQuality: 100,
  compressFormat: "png"
);

if (bytes != null) {
  // do something with cropped oval image 
}
```



