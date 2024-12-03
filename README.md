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
  angle: 0, // Rotate 45 degrees
  width: 150,
  height: 300,
);

if (bytes != null) {
  // do something with cropped oval image 
}
```



