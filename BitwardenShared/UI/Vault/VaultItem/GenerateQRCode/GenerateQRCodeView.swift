import CoreImage.CIFilterBuiltins
import SwiftUI

/// A view that displays a QR code generated from a cipher.
///
struct GenerateQRCodeView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<GenerateQRCodeState, GenerateQRCodeAction, GenerateQRCodeEffect>

    var body: some View {
        VStack(spacing: 16) {
            qrCodeSection
            optionsSection
        }
        .scrollView(padding: 12)
        .navigationBar(title: Localizations.viewAsQRCode, titleDisplayMode: .inline)
        .background(Asset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
        .task {
            await store.perform(.appeared)
        }
    }

    // MARK: Private Properties

    private let context = CIContext()

    private let filter = CIFilter.qrCodeGenerator()

    private var qrCodeSection: some View {
        SectionView(Localizations.wifiLogin) {
            ContentBlock {
                HStack {
                    Spacer()
                    QRCodeView(encodedString: store.state.string)
                    Spacer()
                }
            }
        }
    }

    private var optionsSection: some View {
        SectionView(Localizations.dataToShare, contentSpacing: 8) {
            ContentBlock {
                BitwardenMenuField(
                    title: Localizations.qrCodeType,
                    accessibilityIdentifier: "QRCodeTypeChooser",
                    options: store.state.availableCodeTypes,
                    selection: store.binding(
                        get: \.qrCodeType,
                        send: GenerateQRCodeAction.qrCodeTypeChanged
                    ))
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage {
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
    NavigationView {
        GenerateQRCodeView(
            store: Store(
                processor: StateProcessor(
                    state: GenerateQRCodeState(string: "https://www.google.com")
                )
            )
        )
    }
}

#endif
