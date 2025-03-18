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

    private var qrCodeSection: some View {
        SectionView(Localizations.wifiLogin) {
            ContentBlock {
                HStack {
                    Spacer()
                    QRCodeView(encodedString: store.state.typeState.qrEncodableString)
                    Spacer()
                }
                Text(store.state.typeState.qrEncodableString)
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
                ForEachIndexed(store.state.parameters, id: \.self) { index, parameter in
                    BitwardenMenuField(
                        title: parameter.parameterTitle,
                        options: parameter.options,
                        selection: store.binding(
                            get: { _ in parameter.selected },
                            send: { .parameterChanged($0, index: index) }
                        )
                    )
                }
            }
        }
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
                        typeState: WifiQRCodeState(cipher: .fixture())
                    )
                )
            )
        )
    }
}

#endif
