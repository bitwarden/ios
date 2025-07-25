import AVFoundation
import BitwardenResources
import SwiftUI

// MARK: - ScanCodeView

/// A view that shows the camera to scan QR codes.
struct ScanCodeView: View {
    // MARK: Properties

    /// The AVCaptureSession used to scan qr codes
    let cameraSession: AVCaptureSession

    /// The maximum dynamic type size for the view
    ///     Default is `.xxLarge`
    var maxDynamicTypeSize: DynamicTypeSize = .xxLarge

    /// The `Store` for this view.
    @ObservedObject var store: Store<ScanCodeState, ScanCodeAction, ScanCodeEffect>

    // MARK: Views

    var body: some View {
        content
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
            .navigationTitle(Localizations.scanQrTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismissPressed)
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
            overlayContent
        }
        .edgesIgnoringSafeArea(.horizontal)
    }

    var informationContent: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(Localizations.pointYourCameraAtTheQRCode)
                .styleGuide(.body)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(...maxDynamicTypeSize)
            Spacer()
            Button(
                action: { store.send(.manualEntryPressed) },
                label: {
                    Group {
                        Text(Localizations.cannotScanQRCode + " ")
                            + Text(Localizations.enterKeyManually)
                            .foregroundColor(SharedAsset.Colors.textInteraction.swiftUIColor)
                    }
                    .styleGuide(.body)
                    .multilineTextAlignment(.center)
                    .dynamicTypeSize(...maxDynamicTypeSize)
                }
            )
            .buttonStyle(InlineButtonStyle())
        }
        .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder var overlayContent: some View {
        GeometryReader { proxy in
            if proxy.size.width <= proxy.size.height {
                verticalOverlay
            } else {
                horizontalOverlay
            }
        }
    }

    private var horizontalOverlay: some View {
        GeometryReader { geoProxy in
            let size = geoProxy.size
            let orientation = UIDevice.current.orientation
            let infoBlock = infoBlock(width: size.width / 3, height: size.height)
            HStack(spacing: 0.0) {
                if case .landscapeRight = orientation {
                    infoBlock
                }
                Spacer()
                qrCornerGuides(length: size.height)
                Spacer()
                if orientation != .landscapeRight {
                    infoBlock
                }
            }
        }
    }

    private var verticalOverlay: some View {
        GeometryReader { geoProxy in
            let size = geoProxy.size
            VStack(spacing: 0.0) {
                Spacer()
                qrCornerGuides(length: size.width)
                Spacer()
                infoBlock(width: size.width, height: size.height / 3)
            }
        }
    }

    private func infoBlock(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .frame(
                width: width,
                height: height
            )
            .foregroundColor(.black)
            .opacity(0.5)
            .overlay {
                informationContent
                    .padding(36)
            }
    }

    private func qrCornerGuides(length: CGFloat) -> some View {
        CornerBorderShape(cornerLength: length * 0.1, lineWidth: 3)
            .stroke(lineWidth: 3)
            .foregroundColor(SharedAsset.Colors.iconSecondary.swiftUIColor)
            .frame(
                width: length * 0.65,
                height: length * 0.65
            )
    }
}

#if DEBUG
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
        .navigationViewStyle(.stack)
        .previewDisplayName("Scan Code View")
    }
}
#endif
