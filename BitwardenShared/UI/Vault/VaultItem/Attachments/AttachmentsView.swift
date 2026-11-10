import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - AttachmentsView

/// A view that allows the user to view and edit attachments.
///
struct AttachmentsView: View {
    // MARK: Properties

    /// Whether the file name text field is focused.
    @FocusState private var isFileNameFocused: Bool

    /// An environment variable used to open URLs.
    @Environment(\.openURL) private var openURL

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
            await store.perform(.appeared)
        }
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
        .toast(store.binding(
            get: \.toast,
            send: AttachmentsAction.toastShown,
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

    /// The currently chosen file to add. When the mobile attachment updates feature is enabled, the
    /// name can be edited.
    @ViewBuilder private var chosenFile: some View {
        if let fileName = store.state.fileName {
            if store.state.isMobileAttachmentUpdatesEnabled {
                editableFileName
            } else {
                BitwardenField {
                    Text(fileName)
                        .styleGuide(.body)
                        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                }
                .contentBlock()
            }
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

    /// The chosen file's name, which can be edited. The file's extension is shown in gray directly
    /// after it and can't be changed.
    private var editableFileName: some View {
        BitwardenField(title: Localizations.fileName) {
            HStack(spacing: 0) {
                fileNameStemField

                Text(store.state.fileNameExtension)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
            // Make the whole row, including the extension and the empty space after it, focus the field.
            .contentShape(Rectangle())
            .onTapGesture {
                isFileNameFocused = true
            }
        }
        .contentBlock()
    }

    /// The text field for editing the file name without its extension.
    ///
    /// The field is sized to its text so that the extension sits flush after it. This is done with an
    /// invisible `Text` that the field is overlaid on, rather than `fixedSize` on the field, because the
    /// single-line `Text` shrinks when there isn't enough room. That keeps long names from pushing the
    /// extension off screen, and the field scrolls its text instead.
    private var fileNameStemField: some View {
        Text(store.state.fileNameStem)
            .styleGuide(.body)
            .lineLimit(1)
            .hidden()
            // Leave room for the insertion point after the last character.
            .padding(.trailing, 2)
            .overlay(alignment: .leading) {
                TextField(
                    "",
                    text: store.binding(
                        get: \.fileNameStem,
                        send: AttachmentsAction.fileNameChanged,
                    ),
                )
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .focused($isFileNameFocused)
                .accessibilityIdentifier("AttachmentFileNameEntry")
                .accessibilityLabel(Localizations.fileName)
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
                attachmentRowLabel(attachment)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.send(.attachmentTapped(attachment))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction {
                        store.send(.attachmentTapped(attachment))
                    }

                Button {
                    store.send(.deletePressed(attachment))
                } label: {
                    Image(asset: SharedAsset.Icons.trash24)
                        .imageStyle(.rowIcon(color: SharedAsset.Colors.iconSecondary.swiftUIColor))
                }
                .accessibilityLabel(Localizations.delete)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                store.send(.attachmentTapped(attachment))
            }
        }
        .accessibilityIdentifier("AttachmentRow")
    }

    /// The file name and size of an attachment, which together act as the tappable area of an
    /// attachment row that opens the attachment preview.
    ///
    /// - Parameter attachment: The attachment to display.
    ///
    private func attachmentRowLabel(_ attachment: AttachmentView) -> some View {
        HStack {
            Text(attachment.fileName ?? "")
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if let sizeName = attachment.sizeName {
                Text(sizeName)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .lineLimit(1)
            }
        }
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
                fileName: "photo.jpg",
                fileNameExtension: ".jpg",
                isMobileAttachmentUpdatesEnabled: true,
            ),
        )))
    }
}

#Preview("Attachment Selected, Long Name") {
    NavigationView {
        AttachmentsView(store: Store(processor: StateProcessor(
            state: AttachmentsState(
                fileName: "IMG_20261012_123456_a_very_long_camera_file_name_that_keeps_going_and_going.jpeg",
                fileNameExtension: ".jpeg",
                isMobileAttachmentUpdatesEnabled: true,
            ),
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
                                    sizeName: "10 MB",
                                ),
                                .fixture(
                                    fileName: "selfieWithADog.png",
                                    id: "2",
                                    sizeName: "11.2 MB",
                                ),
                                .fixture(
                                    fileName: "selfieWithAPotato.png",
                                    id: "3",
                                    sizeName: "201.2 MB",
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        )
    }
}
#endif
