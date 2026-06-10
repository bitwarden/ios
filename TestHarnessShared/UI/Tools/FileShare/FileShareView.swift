import BitwardenKit
import SwiftUI

/// A view for testing the Bitwarden Share Extension by sharing text or file content
/// via the iOS share sheet.
///
@available(iOS 16.0, *)
struct FileShareView: View {
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

    /// The section for sharing a sample file.
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
