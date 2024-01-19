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

    /// The add attachment view.
    private var addAttachmentView: some View {
        SectionView(Localizations.addNewAttachment) {
            VStack(spacing: 16) {
                chosenFile

                chooseFileButton
            }
        }
    }

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
        if let attachments = store.state.cipher?.attachments, !attachments.isEmpty {
            VStack(spacing: 0) {
                ForEach(attachments) { attachment in
                    attachmentRow(attachment, hasDivider: attachment != attachments.last)
                }
            }
            .cornerRadius(10)
            .padding(.bottom, 20)
        } else {
            Text(Localizations.noAttachments)
                .styleGuide(.body)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
    }

    /// The save button.
    private var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.save)
        }
        .buttonStyle(.primary())
    }

    /// A row to display an existing attachment.
    ///
    /// - Parameters:
    ///   - attachment: The attachment to display.
    ///   - hasDivider: Whether the row should display a divider.
    ///
    private func attachmentRow(_ attachment: AttachmentView, hasDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(attachment.fileName ?? "")
                    .styleGuide(.body)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    .lineLimit(1)

                Spacer()

                if let sizeName = attachment.sizeName {
                    Text(sizeName)
                        .styleGuide(.body)
                        .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                        .lineLimit(1)
                }

                Button {
                    store.send(.deletePressed(attachment))
                } label: {
                    Image(uiImage: Asset.Images.trash.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)
                        .frame(width: 22, height: 22)
                }
                .accessibilityLabel(Localizations.delete)
            }
            .padding(16)

            if hasDivider {
                Divider()
                    .padding(.leading, 16)
            }
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty Attachments") {
    NavigationView {
        AttachmentsView(store: Store(processor: StateProcessor(state: AttachmentsState())))
    }
}

#Preview("Attachments") {
    NavigationView {
        AttachmentsView(
            store: Store(
                processor: StateProcessor(
                    state: AttachmentsState(
                        cipher: .init(
                            id: nil,
                            organizationId: nil,
                            folderId: nil,
                            collectionIds: [],
                            key: nil,
                            name: "",
                            notes: nil,
                            type: .secureNote,
                            login: nil,
                            identity: nil,
                            card: nil,
                            secureNote: nil,
                            favorite: true,
                            reprompt: .none,
                            organizationUseTotp: false,
                            edit: false,
                            viewPassword: false,
                            localData: nil,
                            attachments: [
                                .init(
                                    id: "1",
                                    url: nil,
                                    size: nil,
                                    sizeName: "10 MB",
                                    fileName: "selfieWithACat.png",
                                    key: nil
                                ),
                                .init(
                                    id: "2",
                                    url: nil,
                                    size: nil,
                                    sizeName: "11.2 MB",
                                    fileName: "selfieWithADog.png",
                                    key: nil
                                ),
                                .init(
                                    id: "3",
                                    url: nil,
                                    size: nil,
                                    sizeName: "201.2 MB",
                                    fileName: "selfieWithAPotato.png",
                                    key: nil
                                ),
                            ],
                            fields: nil,
                            passwordHistory: nil,
                            creationDate: Date(),
                            deletedDate: nil,
                            revisionDate: Date()
                        )
                    )
                )
            )
        )
    }
}
#endif
