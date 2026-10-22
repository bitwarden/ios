import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

// MARK: - AgentAccessQRCode

/// A helper that renders text as a QR code image.
///
enum AgentAccessQRCode {
    /// Renders text as a QR code image.
    ///
    /// - Parameters:
    ///   - text: The text to encode.
    ///   - scale: The number of points used for each QR code module.
    /// - Returns: The QR code image, or `nil` if the text can't be encoded.
    ///
    static func image(for text: String, scale: CGFloat = 10) -> UIImage? {
        guard let data = text.data(using: .utf8) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"

        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: scale, y: scale)),
              let cgImage = CIContext().createCGImage(output, from: output.extent)
        else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
