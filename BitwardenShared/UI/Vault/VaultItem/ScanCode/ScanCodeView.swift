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
            overlayView
        }
    }

    var informationContent: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(Localizations.pointYourCameraAtTheQRCode)
                .font(.styleGuide(.body))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            Spacer()
            Button(
                action: { store.send(.manualEntryPressed) },
                label: {
                    Group {
                        Text(Localizations.cannotScanQRCode + " ")
                            .foregroundColor(.white)
                            + Text(Localizations.enterKeyManually)
                            .foregroundColor(Asset.Colors.primaryBitwardenDark.swiftUIColor)
                    }
                    .font(.styleGuide(.body))
                }
            )
            .buttonStyle(InlineButtonStyle())
        }
    }

    var overlayView: some View {
        GeometryReader { geoProxy in
            overlayContent(size: geoProxy.size)
        }
    }

    @ViewBuilder
    func overlayContent(size: CGSize) -> some View {
        if size.width < size.height {
            VStack(spacing: 0.0) {
                Spacer()
                CornerBorderShape(cornerLength: size.width * 0.1, lineWidth: 3)
                    .stroke(lineWidth: 3)
                    .foregroundColor(Asset.Colors.primaryBitwardenLight.swiftUIColor)
                    .frame(
                        width: size.width * 0.65,
                        height: size.width * 0.65
                    )
                Spacer()
                Rectangle()
                    .frame(
                        width: size.width,
                        height: size.height / 3
                    )
                    .foregroundColor(.black)
                    .opacity(0.5)
                    .overlay {
                        informationContent
                            .padding(36)
                    }
            }
        } else {
            HStack(spacing: 0.0) {
                Spacer()
                CornerBorderShape(cornerLength: size.height * 0.1, lineWidth: 3)
                    .stroke(lineWidth: 3)
                    .foregroundColor(Asset.Colors.primaryBitwardenLight.swiftUIColor)
                    .frame(
                        width: size.height * 0.65,
                        height: size.height * 0.65
                    )
                Spacer()
                Rectangle()
                    .frame(
                        width: size.width / 3,
                        height: size.height
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
        .previewDisplayName("Scan Code View")
    }
}
