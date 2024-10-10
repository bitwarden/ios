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
        .padding(.bottom, FloatingActionButton.bottomOffsetPadding)
        .scrollView()
        .navigationBar(title: Localizations.attachments, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismissPressed)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            addItemFloatingActionButton {
                store.send(.chooseFilePressed)
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
        if store.state.fileName != nil || (store.state.cipher?.attachments?.isEmpty ?? true) {
            Text(store.state.fileName ?? Localizations.noFileChosen)
                .styleGuide(.body)
                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
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
            noAttachementsView
        }
    }

    /// The empty state for the currentAttachments view.
    private var noAttachementsView: some View {
        Text(Localizations.noAttachments)
            .accessibilityIdentifier("NoAttachmentsLabel")
            .styleGuide(.body)
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }

    /// The save button.
    private var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.save)
        }
        .accessibilityIdentifier("SaveButton")
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
                    Image(asset: Asset.Images.trash)
                        .imageStyle(.rowIcon(color: Asset.Colors.iconSecondary.swiftUIColor))
                }
                .accessibilityLabel(Localizations.delete)
            }
            .padding(16)

            if hasDivider {
                Divider()
                    .padding(.leading, 16)
            }
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
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

#Preview("Attachments") {
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
