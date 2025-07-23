import BitwardenResources
import SwiftUI

// MARK: - ViewSendItemView

/// A view that allows the user to view the details of a send item.
///
struct ViewSendItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewSendItemState, ViewSendItemAction, ViewSendItemEffect>

    // MARK: View

    var body: some View {
        content
            .scrollView()
            .navigationBar(title: store.state.navigationTitle, titleDisplayMode: .inline)
            .overlay(alignment: .bottomTrailing) {
                editItemFloatingActionButton {
                    store.send(.editItem)
                }
            }
            .task { await store.perform(.loadData) }
            .task { await store.perform(.streamSend) }
            .toast(
                store.binding(
                    get: \.toast,
                    send: ViewSendItemAction.toastShown
                ),
                additionalBottomPadding: FloatingActionButton.bottomOffsetPadding
            )
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismiss)
                }
            }
    }

    // MARK: Private Views

    /// The button to delete the send.
    private var deleteSendButton: some View {
        AsyncButton {
            await store.perform(.deleteSend)
        } label: {
            Label(Localizations.deleteSend, image: Asset.Images.trash16.swiftUIImage, scaleImageDimension: 16)
        }
        .buttonStyle(.secondary(isDestructive: true, size: .medium))
        .accessibilityIdentifier("ViewSendDeleteButton")
    }

    /// The main content of the view.
    @ViewBuilder private var content: some View {
        VStack(spacing: 16) {
            sendLink

            sendDetailsSection

            additionalOptions

            deleteSendButton
        }
        .animation(.default, value: store.state.isAdditionalOptionsExpanded)
        .padding(.bottom, FloatingActionButton.bottomOffsetPadding)
    }

    /// The expandable additional options section.
    @ViewBuilder private var additionalOptions: some View {
        if store.state.sendView.maxAccessCount != nil || store.state.sendView.notes?.isEmpty == false {
            ExpandableContent(
                title: Localizations.additionalOptions,
                isExpanded: store.binding(
                    get: \.isAdditionalOptionsExpanded,
                    send: { _ in ViewSendItemAction.toggleAdditionalOptions }
                ),
                buttonAccessibilityIdentifier: "SendShowHideOptionsButton"
            ) {
                if let maxAccessCount = store.state.sendView.maxAccessCount {
                    SendItemAccessCountStepper(
                        currentAccessCount: Int(store.state.sendView.accessCount),
                        displayInfoText: false,
                        maximumAccessCount: .constant(Int(maxAccessCount))
                    )
                    .disabled(true)
                }

                if let notes = store.state.sendView.notes, !notes.isEmpty {
                    BitwardenTextValueField(
                        title: Localizations.privateNote,
                        value: notes,
                        useUIKitTextView: true,
                        copyButtonAccessibilityIdentifier: "CopyNotesButton",
                        copyButtonAction: {
                            store.send(.copyNotes)
                        }
                    )
                    .accessibilityIdentifier("ViewSendNotes")
                }
            }
        }
    }

    /// The card containing the send link with copy and share buttons.
    @ViewBuilder private var sendLink: some View {
        ContentBlock {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localizations.sendLink)
                    .styleGuide(.title3, weight: .bold, includeLinePadding: false, includeLineSpacing: false)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

                if let displayShareURL = store.state.displayShareURL {
                    Text(displayShareURL)
                        .styleGuide(.subheadline)
                        .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .lineLimit(1)
                        .accessibilityIdentifier("ViewSendShareLinkText")
                }
            }
            .padding(16)

            VStack(spacing: 12) {
                Button {
                    store.send(.copyShareURL)
                } label: {
                    Label(Localizations.copy, image: Asset.Images.copy16.swiftUIImage, scaleImageDimension: 16)
                }
                .buttonStyle(.primary(size: .medium))
                .accessibilityIdentifier("ViewSendCopyButton")

                Button {
                    store.send(.shareSend)
                } label: {
                    Label(Localizations.share, image: Asset.Images.share16.swiftUIImage, scaleImageDimension: 16)
                }
                .buttonStyle(.secondary(size: .medium))
                .accessibilityIdentifier("ViewSendShareButton")
            }
            .padding(16)
        }
    }

    /// The send details section, containing the send's name, content, and deletion date.
    @ViewBuilder private var sendDetailsSection: some View {
        SectionView(Localizations.sendDetails, contentSpacing: 8) {
            BitwardenTextValueField(
                title: Localizations.sendNameRequired,
                value: store.state.sendView.name,
                valueAccessibilityIdentifier: "ViewSendNameField"
            )

            switch store.state.sendView.type {
            case .file:
                if let file = store.state.sendView.file {
                    BitwardenField {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(file.fileName)
                                .styleGuide(.body)
                                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                                .accessibilityIdentifier("ViewSendFileNameText")

                            if let fileSize = file.sizeName {
                                Text(fileSize)
                                    .styleGuide(.footnote)
                                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .multilineTextAlignment(.trailing)
                                    .accessibilityIdentifier("ViewSendFileSizeText")
                            }
                        }
                    }
                }
            case .text:
                if let text = store.state.sendView.text?.text {
                    BitwardenTextValueField(
                        title: Localizations.textToShare,
                        value: text,
                        valueAccessibilityIdentifier: "ViewSendContentText"
                    )
                }
            }

            BitwardenTextValueField(
                title: Localizations.deletionDate,
                value: store.state.sendView.deletionDate.dateTimeDisplay,
                valueAccessibilityIdentifier: "ViewSendDeletionDateField"
            )
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Text") {
    ViewSendItemView(store: Store(processor: StateProcessor(state: ViewSendItemState(
        sendView: .fixture(
            name: "My text send",
            text: .fixture(text: "Some text to send")
        ),
        shareURL: URL(string: "https://send.bitwarden.com/39ngaol3")
    ))))
    .navStackWrapped
}

#Preview("File") {
    ViewSendItemView(store: Store(processor: StateProcessor(state: ViewSendItemState(
        sendView: .fixture(type: .file, file: .fixture(fileName: "photo_123.jpg", sizeName: "3.25 MB")),
        shareURL: URL(string: "https://send.bitwarden.com/39ngaol3")
    ))))
    .navStackWrapped
}
#endif
