import BitwardenKit
import SwiftUI
import UniformTypeIdentifiers

/// A view for testing the Bitwarden Share Extension by sharing text, file, or image content
/// via the iOS share sheet.
///
@available(iOS 16.0, *)
struct FileShareView: View {
    // MARK: Private Types

    /// A `Transferable` wrapper that exports raw PNG data to the iOS share sheet.
    private struct ShareableImage: Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .png) { $0.data }
        }

        let data: Data
    }

    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<FileShareState, FileShareAction, FileShareEffect>

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
            .task {
                await store.perform(.viewAppeared)
            }
    }

    // MARK: Private Views

    /// The main content view.
    private var content: some View {
        Form {
            shareTextSection
            shareFileSection
            shareImageSection
        }
    }

    /// The section for sharing text content.
    private var shareTextSection: some View {
        Section {
            TextEditor(
                text: store.binding(
                    get: \.textContent,
                    send: FileShareAction.textContentChanged,
                ),
            )
            .frame(minHeight: 80)

            ShareLink(item: store.state.textContent) {
                Label(Localizations.shareText, systemImage: "square.and.arrow.up")
            }
            .disabled(store.state.textContent.isEmpty)
        } header: {
            Text(Localizations.shareText)
        } footer: {
            Text(Localizations.shareTextDescription)
        }
    }

    /// The section for sharing a sample PDF file.
    private var shareFileSection: some View {
        Section {
            if let fileURL = store.state.shareableFileURL {
                ShareLink(
                    item: fileURL,
                    preview: SharePreview(FileShareState.sampleFileName),
                ) {
                    HStack {
                        Label(Localizations.shareFile, systemImage: "doc.badge.arrow.up")
                        Spacer()
                        Text(FileShareState.sampleFileName)
                            .foregroundColor(.secondary)
                            .styleGuide(.body)
                    }
                }
            } else {
                Label(Localizations.shareFile, systemImage: "doc.badge.arrow.up")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text(Localizations.shareFile)
        } footer: {
            Text(Localizations.shareFileDescription)
        }
    }

    /// The section for sharing a generated PNG image.
    private var shareImageSection: some View {
        Section {
            if let imageData = store.state.shareableImageData {
                ShareLink(
                    item: ShareableImage(data: imageData),
                    preview: SharePreview(FileShareState.sampleImageName),
                ) {
                    HStack {
                        Label(Localizations.shareImage, systemImage: "photo.badge.arrow.up")
                        Spacer()
                        Text(FileShareState.sampleImageName)
                            .foregroundColor(.secondary)
                            .styleGuide(.body)
                    }
                }
            } else {
                Label(Localizations.shareImage, systemImage: "photo.badge.arrow.up")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text(Localizations.shareImage)
        } footer: {
            Text(Localizations.shareImageDescription)
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    NavigationView {
        FileShareView(store: Store(processor: StateProcessor(state: FileShareState())))
    }
}
#endif
