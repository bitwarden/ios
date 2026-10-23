import BitwardenKit
import BitwardenResources
import SwiftUI
#if DEBUG
import ImageIO
import UIKit
import UniformTypeIdentifiers
#endif

// MARK: - AttachmentPreviewView

/// A view that previews a vault item's attachment.
///
struct AttachmentPreviewView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AttachmentPreviewState, AttachmentPreviewAction, AttachmentPreviewEffect>

    // MARK: Private Properties

    /// Whether the image is zoomed in. Swiping down pans the image while it's zoomed in, so
    /// swipe-to-dismiss is disabled until the image is zoomed back out.
    @SwiftUI.State private var isZoomed = false

    // MARK: View

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "", titleDisplayMode: .inline)
            .interactiveDismissDisabled(isZoomed)
            .toolbar {
                closeToolbarItem {
                    store.send(.dismissPressed)
                }

                ToolbarItem(placement: .principal) {
                    Text(store.state.truncatedFileName)
                        .styleGuide(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                downloadToolbarItem {
                    await store.perform(.downloadPressed)
                }
            }
    }

    // MARK: Private Views

    /// The main content of the view, based on the current preview content state.
    @ViewBuilder private var content: some View {
        switch store.state.content {
        case let .animatedImage(data):
            AnimatedImageView(data: data, isZoomed: $isZoomed)
        case let .image(data):
            ZoomableImageView(data: data, isZoomed: $isZoomed)
        case let .unsupportedFileType(fileExtension) where !fileExtension.isEmpty:
            emptyStateView(
                message: Localizations.previewUnavailableForXFilesDescriptionLong(fileExtension.uppercased()),
            )
        case .unsupportedFileType:
            emptyStateView(message: Localizations.previewUnavailableDescriptionLong)
        case .fileError, .fileTooLarge:
            emptyStateView(message: Localizations.previewUnavailableDescriptionLong)
        }
    }

    /// The empty state shown for unsupported file types or files that failed to decode, with a
    /// button to fall back to downloading the file.
    ///
    /// - Parameter message: The message explaining why the file can't be previewed.
    ///
    private func emptyStateView(message: String) -> some View {
        IllustratedMessageView(
            image: Asset.Images.Illustrations.previewUnavailable.swiftUIImage,
            style: .mediumImage,
            message: message,
        ) {
            Button(Localizations.download) {
                Task { await store.perform(.downloadPressed) }
            }
            .buttonStyle(.primary(shouldFillWidth: false))
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Image") {
    NavigationView {
        AttachmentPreviewView(store: Store(processor: StateProcessor(
            state: AttachmentPreviewState(
                attachment: .fixture(fileName: "selfieWithACat.png"),
                cipher: .fixture(),
                content: .image(UIImage(systemName: "photo")?.pngData() ?? Data()),
                fileName: "selfieWithACat.png",
                temporaryUrl: URL(fileURLWithPath: "/tmp/preview"),
            ),
        )))
    }
}

#Preview("Animated GIF") {
    NavigationView {
        AttachmentPreviewView(store: Store(processor: StateProcessor(
            state: AttachmentPreviewState(
                attachment: .fixture(fileName: "dancingCat.gif"),
                cipher: .fixture(),
                content: .animatedImage(previewGifData()),
                fileName: "dancingCat.gif",
                temporaryUrl: URL(fileURLWithPath: "/tmp/preview"),
            ),
        )))
    }
}

/// Builds a small animated GIF that cycles through a few SF Symbols, for use in previews.
private func previewGifData() -> Data {
    let data = NSMutableData()
    let symbols = ["photo", "photo.fill", "photo.on.rectangle"]
    guard let destination = CGImageDestinationCreateWithData(
        data,
        UTType.gif.identifier as CFString,
        symbols.count,
        nil,
    ) else { return Data() }
    let frameProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.5]]
    for symbol in symbols {
        guard let image = UIImage(systemName: symbol)?.cgImage else { continue }
        CGImageDestinationAddImage(destination, image, frameProperties as CFDictionary)
    }
    CGImageDestinationFinalize(destination)
    return data as Data
}

#Preview("Unsupported File Type") {
    NavigationView {
        AttachmentPreviewView(store: Store(processor: StateProcessor(
            state: AttachmentPreviewState(
                attachment: .fixture(fileName: "statement.pdf"),
                cipher: .fixture(),
                content: .unsupportedFileType(fileExtension: "pdf"),
                fileName: "statement.pdf",
                temporaryUrl: nil,
            ),
        )))
    }
}

#Preview("File Error") {
    NavigationView {
        AttachmentPreviewView(store: Store(processor: StateProcessor(
            state: AttachmentPreviewState(
                attachment: .fixture(fileName: "selfieWithADog.png"),
                cipher: .fixture(),
                content: .fileError,
                fileName: "selfieWithADog.png",
                temporaryUrl: URL(fileURLWithPath: "/tmp/preview"),
            ),
        )))
    }
}
#endif
