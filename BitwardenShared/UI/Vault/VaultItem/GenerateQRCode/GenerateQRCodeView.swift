import CoreImage.CIFilterBuiltins
import SwiftUI

/// A view that displays a QR code generated from a cipher.
///
struct GenerateQRCodeView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<GenerateQRCodeState, GenerateQRCodeAction, GenerateQRCodeEffect>

    var body: some View {
        VStack {
            qrCodeSection
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
        .navigationTitle("QR Code Placeholder")
        .navigationBarTitleDisplayMode(.inline)
//        .toast(
//            store.binding(
//                get: \.toast,
//                send: ViewItemAction.toastShown
//            ),
//            additionalBottomPadding: FloatingActionButton.bottomOffsetPadding
//        )
        .onAppear {
            Task {
                await store.perform(.appeared)
            }
        }
    }

    // MARK: Private Properties

    private let context = CIContext()

    private let filter = CIFilter.qrCodeGenerator()

    private var qrCodeSection: some View {
        SectionView("Placeholder") {
            Image(uiImage: generateQRCode(from: store.state.string))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
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
    GenerateQRCodeView(
        store: Store(
            processor: StateProcessor(
                state: GenerateQRCodeState(string: "https://www.google.com")
            )
        )
    )
}

#endif
