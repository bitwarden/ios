import CoreImage.CIFilterBuiltins
import SwiftUI

/// A view that displays a QR code generated from a cipher.
///
struct ViewAsQRCodeView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewAsQRCodeState, ViewAsQRCodeAction, ViewAsQRCodeEffect>

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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                closeToolbarButton {
                    store.send(.closeTapped)
                }
            }
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
                Text(store.state.string)
                    .styleGuide(.bodyMonospaced)
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
                        send: ViewAsQRCodeAction.qrCodeTypeChanged
                    )
                )
                ForEachIndexed(store.state.expectedFields, id: \.self) { index, expectedField in
                    BitwardenMenuField(
                        title: expectedField.fieldTitle,
                        options: store.state.fieldsForField(field: expectedField),
                        selection: store.binding(
                            get: { _ in store.state.selectedFields[index] },
                            send: { .additionalFieldChanged($0, index: index) }
                        )
                    )
                }
                ForEachIndexed(store.state.typeState.internalState.parameters, id: \.self) { index, expectedField in
                    BitwardenMenuField(
                        title: expectedField.parameterTitle,
                        options: expectedField.options,
                        selection: store.binding(
                            get: { _ in expectedField.options[expectedField.selectedIndex] },
                            send: { .additionalFieldChanged($0, index: index) }
                        )
                    )
                }   
            }
        }
    }

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
    NavigationView {
        ViewAsQRCodeView(
            store: Store(
                processor: StateProcessor(
                    state: ViewAsQRCodeState(
                        cipher: .fixture(),
                        selectedFields: [.username, .password],
                        typeState: TypeState2(
                            internalState: WifiQRCodeState(cipher: .fixture())
                        )
                    )
                )
            )
        )
    }
}

#endif
