import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - AddEditSendItemView

/// A view that allows the user to add or edit a send item.
///
struct AddEditSendItemView: View { // swiftlint:disable:this type_body_length
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddEditSendItemState, AddEditSendItemAction, AddEditSendItemEffect>

    /// A state variable to track whether the TextField is focused
    @FocusState private var isMaxAccessCountFocused: Bool

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                if store.state.isSendDisabled {
                    InfoContainer(Localizations.sendDisabledWarning)
                        .accessibilityIdentifier("DisabledSendPolicyLabel")
                } else if store.state.isSendHideEmailDisabled {
                    InfoContainer(Localizations.sendOptionsPolicyInEffect)
                        .accessibilityIdentifier("HideEmailAddressPolicyLabel")
                }

                sendDetails

                additionalOptions

                if store.state.mode == .edit {
                    deleteSendButton
                }
            }
            .scrollView()
            .disabled(store.state.isSendDisabled)

            profileSwitcher
        }
        .backport.dismissKeyboardInteractively()
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
        .navigationBar(
            title: store.state.navigationTitle,
            titleDisplayMode: .inline
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                cancelToolbarButton {
                    store.send(.dismissPressed)
                }

                switch store.state.mode {
                case .add,
                     .edit:
                    EmptyView()
                case let .shareExtension(profileSwitcherState):
                    ProfileSwitcherToolbarView(
                        store: store.child(
                            state: { _ in
                                profileSwitcherState
                            },
                            mapAction: { action in
                                .profileSwitcher(action)
                            },
                            mapEffect: { effect in
                                .profileSwitcher(effect)
                            }
                        )
                    )
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                saveToolbarButton {
                    await store.perform(.savePressed)
                }
                .disabled(store.state.isSendDisabled)

                if store.state.mode == .edit {
                    optionsToolbarMenu {
                        if !store.state.isSendDisabled {
                            if store.state.originalSendView?.hasPassword ?? false {
                                AsyncButton(Localizations.removePassword) {
                                    await store.perform(.removePassword)
                                }
                            }
                            AsyncButton(Localizations.copyLink) {
                                await store.perform(.copyLinkPressed)
                            }
                            AsyncButton(Localizations.shareLink) {
                                await store.perform(.shareLinkPressed)
                            }
                        }
                    }
                }
            }
        }
        .toast(store.binding(
            get: \.toast,
            send: AddEditSendItemAction.toastShown
        ))
        .animation(.easeInOut(duration: 0.2), value: store.state.type)
        .animation(.default, value: store.state.isOptionsExpanded)
        .task {
            await store.perform(.loadData)
        }
    }

    /// Additional options.
    @ViewBuilder private var additionalOptions: some View {
        ExpandableContent(
            title: Localizations.additionalOptions,
            isExpanded: store.binding(
                get: \.isOptionsExpanded,
                send: { _ in AddEditSendItemAction.optionsPressed }
            ),
            buttonAccessibilityIdentifier: "SendShowHideOptionsButton"
        ) {
            SendItemAccessCountStepper(
                currentAccessCount: store.state.currentAccessCount,
                maximumAccessCount: store.binding(
                    get: \.maximumAccessCount,
                    send: AddEditSendItemAction.maximumAccessCountStepperChanged
                )
            )

            BitwardenTextField(
                title: Localizations.newPassword,
                text: store.binding(
                    get: \.password,
                    send: AddEditSendItemAction.passwordChanged
                ),
                footer: Localizations.passwordInfo,
                accessibilityIdentifier: "SendNewPasswordEntry",
                isPasswordVisible: store.binding(
                    get: \.isPasswordVisible,
                    send: AddEditSendItemAction.passwordVisibleChanged
                )
            )
            .textFieldConfiguration(.password)

            ContentBlock(dividerLeadingPadding: 16) {
                BitwardenToggle(Localizations.hideEmail, isOn: store.binding(
                    get: \.isHideMyEmailOn,
                    send: AddEditSendItemAction.hideMyEmailChanged
                ))
                .accessibilityIdentifier("SendHideEmailSwitch")
                .disabled(!store.state.isHideMyEmailOn && store.state.isSendHideEmailDisabled)
            }

            BitwardenTextView(
                title: Localizations.privateNote,
                text: store.binding(
                    get: \.notes,
                    send: AddEditSendItemAction.notesChanged
                )
            )
        }
    }

    /// The button to delete the send.
    private var deleteSendButton: some View {
        AsyncButton {
            await store.perform(.deletePressed)
        } label: {
            Label(Localizations.deleteSend, image: Asset.Images.trash16.swiftUIImage, scaleImageDimension: 16)
        }
        .buttonStyle(.secondary(isDestructive: true, size: .medium))
    }

    /// The deletion date field.
    @ViewBuilder private var deletionDate: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            BitwardenMenuField(
                title: Localizations.deletionDate,
                accessibilityIdentifier: "SendDeletionOptionsPicker",
                options: store.state.availableDeletionDateTypes,
                selection: store.binding(
                    get: \.deletionDate,
                    send: AddEditSendItemAction.deletionDateChanged
                )
            )

            Text(Localizations.deletionDateInfo)
                .styleGuide(.footnote)
                .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    /// The attributes for a file type send.
    @ViewBuilder private var fileSendAttributes: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch store.state.mode {
            case .add, .shareExtension:
                if let fileName = store.state.fileName {
                    BitwardenField {
                        Text(fileName)
                            .styleGuide(.body)
                            .accessibilityIdentifier("SendCurrentFileNameLabel")
                            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    if store.state.mode == .add {
                        Button(Localizations.chooseFile) {
                            store.send(.chooseFilePressed)
                        }
                        .buttonStyle(.secondary())
                        .accessibilityIdentifier("SendChooseFileButton")
                    }

                    Text(Localizations.requiredMaximumFileSizeIsX(
                        ByteCountFormatter.string(fromByteCount: Int64(Constants.maxFileSizeBytes), countStyle: .binary)
                    ))
                    .styleGuide(.subheadline)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .padding(.leading, 12)
                }

            case .edit:
                BitwardenField {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        if let fileName = store.state.fileName {
                            Text(fileName)
                                .styleGuide(.body)
                                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                        }

                        Spacer(minLength: 0)

                        if let fileSize = store.state.fileSize {
                            Text(fileSize)
                                .styleGuide(.footnote)
                                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
        }
    }

    /// The name field.
    @ViewBuilder private var nameField: some View {
        BitwardenTextField(
            title: Localizations.sendNameRequired,
            text: store.binding(
                get: \.name,
                send: AddEditSendItemAction.nameChanged
            ),
            accessibilityIdentifier: "SendNameEntry"
        )
    }

    /// A view that displays the ability to add or switch between account profiles
    @ViewBuilder private var profileSwitcher: some View {
        switch store.state.mode {
        case let .shareExtension(profileSwitcherState):
            ProfileSwitcherView(
                store: store.child(
                    state: { _ in
                        profileSwitcherState
                    },
                    mapAction: { action in
                        .profileSwitcher(action)
                    },
                    mapEffect: { profileEffect in
                        .profileSwitcher(profileEffect)
                    }
                )
            )
        default: EmptyView()
        }
    }

    /// Additional details for the send.
    @ViewBuilder private var sendDetails: some View {
        SectionView(Localizations.sendDetails, contentSpacing: 8) {
            nameField

            switch store.state.type {
            case .text:
                textSendAttributes
            case .file:
                fileSendAttributes
            }

            if store.state.type == .text {
                ContentBlock {
                    BitwardenToggle(Localizations.hideTextByDefault, isOn: store.binding(
                        get: \.isHideTextByDefaultOn,
                        send: AddEditSendItemAction.hideTextByDefaultChanged
                    ))
                    .accessibilityIdentifier("SendHideTextByDefaultToggle")
                }
            }

            deletionDate
        }
    }

    /// The attributes for a text type send.
    @ViewBuilder private var textSendAttributes: some View {
        BitwardenTextView(
            title: Localizations.textToShare,
            text: store.binding(
                get: \.text,
                send: AddEditSendItemAction.textChanged
            )
        )
        .accessibilityIdentifier("SendTextContentEntry")
    }
}

// MARK: Previews

#if DEBUG
#Preview("Empty") {
    NavigationView {
        AddEditSendItemView(
            store: Store(
                processor: StateProcessor(
                    state: AddEditSendItemState()
                )
            )
        )
    }
}

#Preview("File") {
    NavigationView {
        AddEditSendItemView(
            store: Store(
                processor: StateProcessor(
                    state: AddEditSendItemState(
                        fileName: "Example File",
                        isHideTextByDefaultOn: true,
                        name: "Sendy",
                        type: .file
                    )
                )
            )
        )
    }
}

#Preview("Text") {
    NavigationView {
        AddEditSendItemView(
            store: Store(
                processor: StateProcessor(
                    state: AddEditSendItemState(
                        isHideTextByDefaultOn: true,
                        name: "Sendy",
                        text: "Example text",
                        type: .text
                    )
                )
            )
        )
    }
}

#Preview("Options") {
    NavigationView {
        AddEditSendItemView(
            store: Store(
                processor: StateProcessor(
                    state: AddEditSendItemState(
                        isOptionsExpanded: true
                    )
                )
            )
        )
    }
}

#Preview("Text - Edit") {
    NavigationView {
        AddEditSendItemView(
            store: Store(
                processor: StateProcessor(
                    state: AddEditSendItemState(
                        currentAccessCount: 42,
                        customDeletionDate: Date(),
                        deletionDate: .custom(.now),
                        isHideTextByDefaultOn: true,
                        isOptionsExpanded: true,
                        mode: .edit,
                        name: "Sendy",
                        text: "Example text",
                        type: .text
                    )
                )
            )
        )
    }
}

#Preview("File - Edit") {
    NavigationView {
        AddEditSendItemView(
            store: Store(
                processor: StateProcessor(
                    state: AddEditSendItemState(
                        currentAccessCount: 42,
                        customDeletionDate: Date(),
                        deletionDate: .custom(.now),
                        fileName: "example.txt",
                        fileSize: "420.42 KB",
                        isHideTextByDefaultOn: true,
                        isOptionsExpanded: true,
                        mode: .edit,
                        name: "Sendy",
                        type: .file
                    )
                )
            )
        )
    }
}

#Preview("Text - Share") {
    NavigationView {
        AddEditSendItemView(
            store: Store(
                processor: StateProcessor(
                    state: AddEditSendItemState(
                        currentAccessCount: 42,
                        customDeletionDate: Date(),
                        deletionDate: .custom(.now),
                        isHideTextByDefaultOn: true,
                        isOptionsExpanded: true,
                        mode: .shareExtension(.singleAccount),
                        name: "Sendy",
                        text: "Example text",
                        type: .text
                    )
                )
            )
        )
    }
}

#endif // swiftlint:disable:this file_length
