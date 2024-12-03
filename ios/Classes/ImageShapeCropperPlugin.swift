import Flutter
import UIKit

public class ImageShapeCropperPlugin: NSObject, FlutterPlugin {
    // Declare the channel as an instance variable
    private var channel: FlutterMethodChannel?

    // Register the plugin with the Flutter registrar
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "image_shape_cropper", binaryMessenger: registrar.messenger())
        let instance = ImageShapeCropperPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // Handle incoming method calls from Flutter
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "cropOval":
            guard let args = call.arguments as? [String: Any],
                  let sourcePath = args["sourcePath"] as? String else {
                print("cropOval called with invalid arguments.")
                result(FlutterError(code: "INVALID_ARGUMENT", message: "sourcePath is missing", details: nil))
                return
            }

            let angle = args["angle"] as? Double ?? 0.0
            let width = args["width"] as? Double
            let height = args["height"] as? Double
            let scale = args["scale"] as? Double ?? 0.0 // Default to 0.0 (no zoom)
            let compressFormat = args["compressFormat"] as? String ?? "png"
            let compressQuality = args["compressQuality"] as? Int ?? 100

            print("cropOval called with sourcePath: \(sourcePath), angle: \(angle), width: \(String(describing: width)), height: \(String(describing: height)), scale: \(scale), compressFormat: \(compressFormat), compressQuality: \(compressQuality)")

            guard let image = UIImage(contentsOfFile: sourcePath) else {
                print("Cannot load image from path: \(sourcePath)")
                result(FlutterError(code: "INVALID_IMAGE", message: "Cannot load image", details: nil))
                return
            }

            // Rotate the image
            guard let rotatedImage = rotateImage(image: image, angle: CGFloat(angle)) else {
                print("Failed to rotate image.")
                result(FlutterError(code: "ROTATE_FAILED", message: "Failed to rotate image", details: nil))
                return
            }
            print("Image rotated by \(angle) degrees.")

            // Crop to oval with scaling
            let ovalImage = cropOvalImage(image: rotatedImage, width: width, height: height, scale: scale)
            print("Image cropped to oval.")

            // Compress the image
            var imageData: Data?
            if compressFormat.lowercased() == "png" {
                imageData = ovalImage.pngData()
                print("Compressing image to PNG format.")
            } else {
                let quality = CGFloat(compressQuality) / 100.0
                imageData = ovalImage.jpegData(compressionQuality: quality)
                print("Compressing image to JPEG format with quality \(compressQuality).")
            }

            if let data = imageData {
                print("Image compressed. Size: \(data.count) bytes.")
                result(data)
            } else {
                print("Failed to compress image.")
                result(FlutterError(code: "CROP_FAILED", message: "Failed to get image data", details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // Helper method to rotate the image by a given angle
    private func rotateImage(image: UIImage, angle: CGFloat) -> UIImage? {
        let radians = angle * CGFloat.pi / 180
        var newSize = CGRect(origin: CGPoint.zero, size: image.size).applying(CGAffineTransform(rotationAngle: radians)).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Move origin to middle
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate around middle
        context.rotate(by: radians)
        // Draw the image at its center
        image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2,
                              width: image.size.width, height: image.size.height))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage
    }

    // Helper method to crop the image into an oval shape with scaling
    private func cropOvalImage(image: UIImage, width: Double?, height: Double?, scale: Double) -> UIImage {
        // Convert desiredWidth and desiredHeight from pixels to points
        // iOS UIImage.size is in points, and UIImage.scale represents pixels per point
        let desiredWidthPoints = (width ?? Double(image.size.width)) / Double(image.scale)
        let desiredHeightPoints = (height ?? Double(image.size.height)) / Double(image.scale)

        // Clamp the scale between 0.0 and 5.0
        let effectiveScale: Double
        if scale < 0.0 {
            effectiveScale = 0.0
        } else if scale > 5.0 {
            effectiveScale = 5.0
        } else {
            effectiveScale = scale
        }

        // Calculate the size of the crop rectangle based on scale
        // Using (1 + scale) to ensure:
        // scale = 0.0 -> cropWidth = desiredWidthPoints (no zoom)
        // scale = 1.0 -> cropWidth = desiredWidthPoints / 2 (1x zoom)
        // scale = 2.0 -> cropWidth = desiredWidthPoints / 3 (2x zoom), etc.
        let cropWidth = CGFloat(desiredWidthPoints) / CGFloat(1 + effectiveScale)
        let cropHeight = CGFloat(desiredHeightPoints) / CGFloat(1 + effectiveScale)

        // Calculate the top-left coordinates for center-cropping
        let left = (image.size.width - cropWidth) / 2
        let top = (image.size.height - cropHeight) / 2

        // Ensure crop bounds are within the source image
        let finalCropWidth = left < 0 ? image.size.width : min(cropWidth, image.size.width - left)
        let finalCropHeight = top < 0 ? image.size.height : min(cropHeight, image.size.height - top)

        // Center-crop the image
        guard let cgImage = image.cgImage?.cropping(to: CGRect(x: left, y: top, width: finalCropWidth, height: finalCropHeight)) else {
            return image
        }
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // Scale the cropped image back to desired size with scale factor 1.0
        let scaledImage = UIGraphicsImageRenderer(size: CGSize(width: desiredWidthPoints, height: desiredHeightPoints), format: {
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1.0 // Set scale to 1.0 to prevent automatic scaling
            return format
        }()).image { _ in
            croppedImage.draw(in: CGRect(x: 0, y: 0, width: CGFloat(desiredWidthPoints), height: CGFloat(desiredHeightPoints)))
        }

        // Create a new image with oval mask with scale factor 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: desiredWidthPoints, height: desiredHeightPoints), format: {
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1.0 // Set scale to 1.0 to prevent automatic scaling
            return format
        }())
        let ovalImage = renderer.image { context in
            // Draw the oval path
            let rect = CGRect(x: 0, y: 0, width: CGFloat(desiredWidthPoints), height: CGFloat(desiredHeightPoints))
            context.cgContext.addEllipse(in: rect)
            context.cgContext.clip()

            // Draw the scaled image within the oval
            scaledImage.draw(in: rect)
        }

        // Convert back to pixels by multiplying by image.scale
        let finalImage = UIImage(cgImage: ovalImage.cgImage!, scale: image.scale, orientation: ovalImage.imageOrientation)

        return finalImage
    }
}
