import CoreImage.CIFilterBuiltins
import SwiftUI

// MARK: - QRCodeView

/// A view for displaying a QR code.
///
struct QRCodeView: View {
    // MARK: Properties

    /// The string encoded by the QR code.
    let encodedString: String

    // MARK: Private Properties

    /// The CoreImage Context for generating a QR code.
    private let context = CIContext()

    /// The CoreImage Filter for generating a QR code.
    private let filter = CIFilter.qrCodeGenerator()

    // MARK: View

    var body: some View {
        Image(uiImage: viewAsQRCode(from: encodedString))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .padding(16)
    }

    // MARK: Private Functions

    private func viewAsQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

// MARK: Previews

#if DEBUG

#Preview {
    QRCodeView(encodedString: "https://www.bitwarden.com")
}

#endif
