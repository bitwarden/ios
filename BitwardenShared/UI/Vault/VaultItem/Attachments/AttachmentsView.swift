import BitwardenResources
import BitwardenSdk
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
        VStack(alignment: .center, spacing: 16) {
            currentAttachments

            addAttachmentView
        }
        .scrollView()
        .navigationBar(title: Localizations.attachments, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismissPressed)
            }

            saveToolbarItem {
                await store.perform(.save)
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

    /// The add attachment view.
    private var addAttachmentView: some View {
        SectionView(Localizations.addNewAttachment, contentSpacing: 8) {
            VStack(spacing: 12) {
                chosenFile

                chooseFileButton
            }
        }
    }

    /// The choose file button and the maximum size text beneath it.
    private var chooseFileButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(Localizations.chooseFile) {
                store.send(.chooseFilePressed)
            }
            .buttonStyle(.secondary())

            Text(Localizations.maxFileSize)
                .styleGuide(.subheadline)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .padding(.leading, 12)
        }
    }

    /// The currently chosen file to add.
    @ViewBuilder private var chosenFile: some View {
        if let fileName = store.state.fileName {
            BitwardenField {
                Text(fileName)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            }
            .contentBlock()
        }
    }

    /// The view of current attachments.
    @ViewBuilder private var currentAttachments: some View {
        SectionView(Localizations.attachments, contentSpacing: 8) {
            ContentBlock {
                if let attachments = store.state.cipher?.attachments, !attachments.isEmpty {
                    ForEach(attachments) { attachment in
                        attachmentRow(attachment, hasDivider: attachment != attachments.last)
                    }
                } else {
                    noAttachmentsView
                }
            }
        }
    }

    /// The empty state for the currentAttachments view.
    private var noAttachmentsView: some View {
        BitwardenField {
            Text(Localizations.noAttachments)
                .accessibilityIdentifier("NoAttachmentsLabel")
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
        }
    }

    /// A row to display an existing attachment.
    ///
    /// - Parameters:
    ///   - attachment: The attachment to display.
    ///   - hasDivider: Whether the row should display a divider.
    ///
    private func attachmentRow(_ attachment: AttachmentView, hasDivider: Bool) -> some View {
        BitwardenField {
            HStack {
                Text(attachment.fileName ?? "")
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .lineLimit(1)

                Spacer()

                if let sizeName = attachment.sizeName {
                    Text(sizeName)
                        .styleGuide(.body)
                        .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .lineLimit(1)
                }

                Button {
                    store.send(.deletePressed(attachment))
                } label: {
                    Image(asset: Asset.Images.trash24)
                        .imageStyle(.rowIcon(color: SharedAsset.Colors.iconSecondary.swiftUIColor))
                }
                .accessibilityLabel(Localizations.delete)
            }
        }
        .accessibilityIdentifier("AttachmentRow")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty Attachments") {
    NavigationView {
        AttachmentsView(store: Store(processor: StateProcessor(state: AttachmentsState())))
    }
}

#Preview("Attachment Selected") {
    NavigationView {
        AttachmentsView(store: Store(processor: StateProcessor(
            state: AttachmentsState(
                fileName: "photo.jpg"
            )
        )))
    }
}

#Preview("Existing Attachments") {
    NavigationView {
        AttachmentsView(
            store: Store(
                processor: StateProcessor(
                    state: AttachmentsState(
                        cipher: .fixture(
                            attachments: [
                                .fixture(
                                    fileName: "selfieWithACat.png",
                                    id: "1",
                                    sizeName: "10 MB"
                                ),
                                .fixture(
                                    fileName: "selfieWithADog.png",
                                    id: "2",
                                    sizeName: "11.2 MB"
                                ),
                                .fixture(
                                    fileName: "selfieWithAPotato.png",
                                    id: "3",
                                    sizeName: "201.2 MB"
                                ),
                            ]
                        )
                    )
                )
            )
        )
    }
}
#endif
