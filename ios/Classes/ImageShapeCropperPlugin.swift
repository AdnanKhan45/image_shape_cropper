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
            let width = args["width"] as? Int
            let height = args["height"] as? Int
            let compressFormat = args["compressFormat"] as? String ?? "png"
            let compressQuality = args["compressQuality"] as? Int ?? 100

            print("cropOval called with sourcePath: \(sourcePath), angle: \(angle), width: \(String(describing: width)), height: \(String(describing: height)), compressFormat: \(compressFormat), compressQuality: \(compressQuality)")

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

            // Crop to oval without stretching
            let ovalImage = cropOvalImage(image: rotatedImage, width: width, height: height)
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

    // Helper method to crop the image into an oval shape
    private func cropOvalImage(image: UIImage, width: Int?, height: Int?) -> UIImage {
        let desiredWidth = CGFloat(width ?? Int(image.size.width))
        let desiredHeight = CGFloat(height ?? Int(image.size.height))
        let desiredSize = CGSize(width: desiredWidth, height: desiredHeight)

        // Calculate aspect ratios
        let desiredAspect = desiredWidth / desiredHeight
        let sourceAspect = image.size.width / image.size.height

        var scale: CGFloat
        var scaledWidth: CGFloat
        var scaledHeight: CGFloat

        if sourceAspect > desiredAspect {
            // Source is wider than desired aspect ratio
            scale = desiredHeight / image.size.height
        } else {
            // Source is taller than desired aspect ratio
            scale = desiredWidth / image.size.width
        }

        scaledWidth = image.size.width * scale
        scaledHeight = image.size.height * scale

        // Scale the image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: scaledWidth, height: scaledHeight), false, image.scale)
        image.draw(in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let scaled = scaledImage else {
            return image
        }

        // Calculate the top-left coordinates for center-cropping
        let x = (scaledWidth - desiredWidth) / 2
        let y = (scaledHeight - desiredHeight) / 2
        let cropRect = CGRect(x: x, y: y, width: desiredWidth, height: desiredHeight)

        // Center-crop the image
        guard let cgImage = scaled.cgImage?.cropping(to: cropRect) else {
            return image
        }
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // Create a new image with oval mask
        UIGraphicsBeginImageContextWithOptions(desiredSize, false, image.scale)
        let context = UIGraphicsGetCurrentContext()

        // Draw the oval path
        let rect = CGRect(origin: .zero, size: desiredSize)
        context?.addEllipse(in: rect)
        context?.clip()

        // Draw the cropped image within the oval
        croppedImage.draw(in: rect)

        let ovalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return ovalImage ?? image
    }

}
