import AVFoundation
import SwiftUI

// MARK: - ScanCodeView

/// A view that shows the camera to scan QR codes.
struct ScanCodeView: View {
    // MARK: Properties

    /// The AVCaptureSession used to scan qr codes
    let cameraSession: AVCaptureSession

    /// The `Store` for this view.
    @ObservedObject var store: Store<ScanCodeState, ScanCodeAction, ScanCodeEffect>

    var body: some View {
        content
            .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
            .navigationTitle(Localizations.scanQrTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ToolbarButton(asset: Asset.Images.cancel, label: Localizations.close) {
                        store.send(.dismissPressed)
                    }
                }
            }
            .task {
                await store.perform(.appeared)
            }
            .onDisappear {
                Task {
                    await store.perform(.disappeared)
                }
            }
    }

    var content: some View {
        ZStack {
            CameraPreviewView(session: cameraSession)
            informationOverlay
        }
    }

    var informationContent: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Point your camera at the QR code. Scanning will happen automatically.")
                .font(.styleGuide(.body))
                .multilineTextAlignment(.center)
                .foregroundColor(Asset.Colors.textPrimaryInverted.swiftUIColor)
            Spacer()
            Button(
                action: { store.send(.manualEntryPressed) },
                label: {
                    Group {
                        Text("Cannot scan QR code? ")
                            .foregroundColor(Asset.Colors.textPrimaryInverted.swiftUIColor)
                            + Text("Enter manually")
                            .foregroundColor(Asset.Colors.primaryBitwardenDark.swiftUIColor)
                    }
                    .font(.styleGuide(.body))
                }
            )
            .buttonStyle(InlineButtonStyle())
        }
    }

    var informationOverlay: some View {
        GeometryReader { geoProxy in
            VStack(spacing: 0.0) {
                Spacer()
                CornerBorderShape(cornerLength: geoProxy.size.width * 0.1, lineWidth: 3)
                    .stroke(lineWidth: 3)
                    .foregroundColor(.blue)
                    .frame(
                        width: geoProxy.size.width * 0.65,
                        height: geoProxy.size.width * 0.65
                    )
                Spacer()
                Rectangle()
                    .frame(
                        width: geoProxy.size.width,
                        height: geoProxy.size.height / 3
                    )
                    .foregroundColor(.black)
                    .opacity(0.5)
                    .overlay {
                        informationContent
                            .padding(36)
                    }
            }
        }
    }
}

struct ScanCodeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScanCodeView(
                cameraSession: AVCaptureSession(),
                store: Store(
                    processor: StateProcessor(
                        state: ScanCodeState()
                    )
                )
            )
        }
    }
}
