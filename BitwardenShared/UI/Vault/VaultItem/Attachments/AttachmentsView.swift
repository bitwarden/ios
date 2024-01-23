import SwiftUI

// MARK: - AttachmentsView

/// A view that allows the user to view and edit attachments.
///
struct AttachmentsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AttachmentsState, AttachmentsAction, AttachmentsEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            currentAttachments

            addAttachmentView

            saveButton
        }
        .scrollView()
        .navigationBar(title: Localizations.attachments, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismissPressed)
            }
        }
        .task {
            await store.perform(.loadPremiumStatus)
        }
        .toast(store.binding(
            get: \.toast,
            send: AttachmentsAction.toastShown
        ))
    }

    // MARK: Private Views

    /// The choose file button and the maximum size text beneath it.
    private var chooseFileButton: some View {
        VStack(alignment: .leading, spacing: 7) {
            Button(Localizations.chooseFile) {
                store.send(.chooseFilePressed)
            }
            .buttonStyle(.tertiary())

            Text(Localizations.maxFileSize)
                .styleGuide(.subheadline)
                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
        }
    }

    /// The currently chosen file to add.
    @ViewBuilder private var chosenFile: some View {
        Text(store.state.fileName ?? Localizations.noFileChosen)
            .styleGuide(.body)
            .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// The view of current attachments.
    @ViewBuilder private var currentAttachments: some View {
        if store.state.cipher?.attachments?.isEmpty ?? true {
            Text(Localizations.noAttachments)
                .styleGuide(.body)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
    }

    /// The add attachment view.
    private var addAttachmentView: some View {
        SectionView(Localizations.addNewAttachment) {
            VStack(spacing: 16) {
                chosenFile

                chooseFileButton
            }
        }
    }

    /// The save button.
    private var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.save)
        }
        .buttonStyle(.primary())
    }
}

// MARK: - Previews

#Preview("Empty Attachments") {
    NavigationView {
        AttachmentsView(store: Store(processor: StateProcessor(state: AttachmentsState())))
    }
}
