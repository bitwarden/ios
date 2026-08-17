import BitwardenKit
import BitwardenResources
import SwiftUI
#if DEBUG
import UIKit
#endif

// MARK: - AttachmentPreviewView

/// A view that previews a vault item's attachment.
///
struct AttachmentPreviewView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AttachmentPreviewState, AttachmentPreviewAction, AttachmentPreviewEffect>

    // MARK: View

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "", titleDisplayMode: .inline)
            .toolbar {
                closeToolbarItem {
                    store.send(.dismissPressed)
                }

                ToolbarItem(placement: .principal) {
                    Text(store.state.truncatedFileName)
                        .styleGuide(.headline)
                        .lineLimit(1)
                }

                downloadToolbarItem {
                    await store.perform(.downloadPressed)
                }
            }
            .toast(store.binding(
                get: \.toast,
                send: AttachmentPreviewAction.toastShown,
            ))
    }

    // MARK: Private Views

    /// The main content of the view, based on the current preview content state.
    @ViewBuilder private var content: some View {
        switch store.state.content {
        case let .image(data):
            ZoomableImageView(data: data)
        case let .unsupportedFileType(fileExtension):
            emptyStateView(
                message: Localizations.previewUnavailableForXFilesDescriptionLong(fileExtension.uppercased()),
            )
        case .fileError:
            emptyStateView(message: Localizations.previewUnavailableDescriptionLong)
        }
    }

    /// The empty state shown for unsupported file types or files that failed to decode, with a
    /// button to fall back to downloading the file.
    ///
    /// - Parameter message: The message explaining why the file can't be previewed.
    ///
    private func emptyStateView(message: String) -> some View {
        // TODO: PM-33413 swap in the final Figma illustration once design provides it.
        IllustratedMessageView(
            image: Asset.Images.Illustrations.dataBreach.swiftUIImage,
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
                content: .image(UIImage(systemName: "photo")?.pngData() ?? Data()),
                fileName: "selfieWithACat.png",
                temporaryUrl: URL(fileURLWithPath: "/tmp/preview"),
            ),
        )))
    }
}

#Preview("Unsupported File Type") {
    NavigationView {
        AttachmentPreviewView(store: Store(processor: StateProcessor(
            state: AttachmentPreviewState(
                attachment: .fixture(fileName: "statement.pdf"),
                content: .unsupportedFileType(fileExtension: "pdf"),
                fileName: "statement.pdf",
                temporaryUrl: URL(fileURLWithPath: "/tmp/preview"),
            ),
        )))
    }
}

#Preview("File Error") {
    NavigationView {
        AttachmentPreviewView(store: Store(processor: StateProcessor(
            state: AttachmentPreviewState(
                attachment: .fixture(fileName: "selfieWithADog.png"),
                content: .fileError,
                fileName: "selfieWithADog.png",
                temporaryUrl: URL(fileURLWithPath: "/tmp/preview"),
            ),
        )))
    }
}
#endif
