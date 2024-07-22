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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if store.state.isSendDisabled {
                        InfoContainer(Localizations.sendDisabledWarning)
                    } else if store.state.isSendHideEmailDisabled {
                        InfoContainer(Localizations.sendOptionsPolicyInEffect)
                    }

                    nameField

                    if store.state.mode == .add {
                        typePicker
                    }

                    switch store.state.type {
                    case .text:
                        textSendAttributes
                    case .file:
                        fileSendAttributes
                    }

                    optionsButton

                    if store.state.isOptionsExpanded {
                        options
                    }

                    saveButton
                }
                .padding(16)
                .disabled(store.state.isSendDisabled)
            }
            profileSwitcher
        }
        .dismissKeyboardInteractively()
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationBar(
            title: store.state.mode.navigationTitle,
            titleDisplayMode: .inline
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
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

                cancelToolbarButton {
                    store.send(.dismissPressed)
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                switch store.state.mode {
                case .edit:
                    optionsToolbarMenu {
                        if !store.state.isSendDisabled {
                            AsyncButton(Localizations.shareLink) {
                                await store.perform(.shareLinkPressed)
                            }
                            AsyncButton(Localizations.copyLink) {
                                await store.perform(.copyLinkPressed)
                            }
                            if store.state.originalSendView?.hasPassword ?? false {
                                AsyncButton(Localizations.removePassword) {
                                    await store.perform(.removePassword)
                                }
                            }
                        }

                        AsyncButton(Localizations.delete, role: .destructive) {
                            await store.perform(.deletePressed)
                        }
                    }
                case .add,
                     .shareExtension:
                    EmptyView()
                }
            }
        }
        .toast(store.binding(
            get: \.toast,
            send: AddEditSendItemAction.toastShown
        ))
        .animation(.easeInOut(duration: 0.2), value: store.state.type)
        .animation(.easeInOut(duration: 0.2), value: store.state.deletionDate)
        .animation(.easeInOut(duration: 0.2), value: store.state.expirationDate)
        .animation(.default, value: store.state.isOptionsExpanded)
        .task {
            await store.perform(.loadData)
        }
    }

    /// The access count stepper.
    @ViewBuilder private var accessCount: some View {
        VStack(alignment: .leading, spacing: 8) {
            Stepper(
                value: store.binding(
                    get: \.maximumAccessCount,
                    send: AddEditSendItemAction.maximumAccessCountStepperChanged
                ),
                in: 0 ... Int.max
            ) {
                HStack(spacing: 8) {
                    Text(Localizations.maximumAccessCount)
                        .styleGuide(.body)
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                        .layoutPriority(1)

                    Spacer()

                    TextField(
                        "",
                        text: store.binding(
                            get: \.maximumAccessCountText,
                            send: AddEditSendItemAction.maximumAccessCountTextFieldChanged
                        )
                    )
                    .focused($isMaxAccessCountFocused)
                    .keyboardType(.numberPad)
                    .styleGuide(.body)
                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button(Localizations.save) {
                                isMaxAccessCountFocused = false
                            }
                        }
                    }
                    .accessibilityIdentifier("MaxAccessCountTextField")
                }
            }
            .accessibilityIdentifier("SendMaxAccessCountEntry")

            Text(Localizations.maximumAccessCountInfo)
                .styleGuide(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

            if let currentAccessCount = store.state.currentAccessCount {
                // Wrap these texts in a group so that the style guide can be set on
                // both of them at once.
                Group {
                    Text("\(Localizations.currentAccessCount): ")
                        + Text("\(currentAccessCount)")
                        .fontWeight(.bold)
                }
                .styleGuide(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
            }
        }
    }

    /// The deletion date field.
    @ViewBuilder private var deletionDate: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch store.state.mode {
            case .add,
                 .shareExtension:
                BitwardenMenuField(
                    title: Localizations.deletionDate,
                    accessibilityIdentifier: "SendDeletionOptionsPicker",
                    options: SendDeletionDateType.allCases,
                    selection: store.binding(
                        get: \.deletionDate,
                        send: AddEditSendItemAction.deletionDateChanged
                    )
                )
            case .edit:
                Text(Localizations.deletionDate)
                    .styleGuide(.subheadline, weight: .semibold)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .padding(.bottom, 8.0)
            }

            if store.state.deletionDate == .custom {
                AccessibleHStack(alignment: .leading, spacing: 8) {
                    BitwardenDatePicker(
                        selection: store.binding(
                            get: \.customDeletionDate,
                            send: AddEditSendItemAction.customDeletionDateChanged
                        ),
                        displayComponents: .date,
                        accessibilityIdentifier: "SendCustomDeletionDatePicker"
                    )

                    BitwardenDatePicker(
                        selection: store.binding(
                            get: \.customDeletionDate,
                            send: AddEditSendItemAction.customDeletionDateChanged
                        ),
                        displayComponents: .hourAndMinute,
                        accessibilityIdentifier: "SendCustomDeletionTimePicker"
                    )
                }
            }

            Text(Localizations.deletionDateInfo)
                .styleGuide(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
        }
    }

    /// The expiration date field.
    @ViewBuilder private var expirationDate: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch store.state.mode {
            case .add,
                 .shareExtension:
                BitwardenMenuField(
                    title: Localizations.expirationDate,
                    accessibilityIdentifier: "SendExpirationOptionsPicker",
                    options: SendExpirationDateType.allCases,
                    selection: store.binding(
                        get: \.expirationDate,
                        send: AddEditSendItemAction.expirationDateChanged
                    )
                )
            case .edit:
                Text(Localizations.expirationDate)
                    .styleGuide(.subheadline, weight: .semibold)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .padding(.bottom, 8.0)
            }

            if store.state.expirationDate == .custom {
                AccessibleHStack(alignment: .leading, spacing: 8) {
                    BitwardenDatePicker(
                        selection: store.binding(
                            get: \.customExpirationDate,
                            send: AddEditSendItemAction.customExpirationDateChanged
                        ),
                        displayComponents: .date,
                        accessibilityIdentifier: "SendCustomExpirationDatePicker"
                    )

                    BitwardenDatePicker(
                        selection: store.binding(
                            get: \.customExpirationDate,
                            send: AddEditSendItemAction.customExpirationDateChanged
                        ),
                        displayComponents: .hourAndMinute,
                        accessibilityIdentifier: "SendCustomDeletionTimePicker"
                    )
                }
            }

            HStack(spacing: 8) {
                Text(Localizations.expirationDateInfo)
                    .styleGuide(.footnote)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

                if store.state.mode == .edit {
                    Spacer()

                    Button(Localizations.clear) {
                        store.send(.clearExpirationDatePressed)
                    }
                    .accessibilityIdentifier("Clear")
                    .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .accessibilityIdentifier("SendClearExpirationDateButton")
                }
            }
        }
    }

    /// The attributes for a file type send.
    @ViewBuilder private var fileSendAttributes: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Localizations.file)
                .styleGuide(.subheadline, weight: .semibold)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

            switch store.state.mode {
            case .add, .shareExtension:
                HStack(spacing: 0) {
                    Spacer()

                    Text(store.state.fileName ?? Localizations.noFileChosen)
                        .styleGuide(.callout)
                        .accessibilityIdentifier(store.state.fileName != nil ? "SendCurrentFileNameLabel" : "")
                        .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    if store.state.mode == .add {
                        Button(Localizations.chooseFile) {
                            store.send(.chooseFilePressed)
                        }
                        .buttonStyle(.tertiary())
                        .accessibilityIdentifier("SendChooseFileButton")
                    }

                    Text(Localizations.maxFileSize)
                        .styleGuide(.subheadline)
                        .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                }

                Text(Localizations.typeFileInfo)
                    .styleGuide(.footnote)
                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)

            case .edit:
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let fileName = store.state.fileName {
                        Text(fileName)
                            .styleGuide(.body)
                            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    }

                    Spacer()

                    if let fileSize = store.state.fileSize {
                        Text(fileSize)
                            .styleGuide(.footnote)
                            .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                    }
                }
            }
        }
    }

    /// The name field.
    @ViewBuilder private var nameField: some View {
        BitwardenTextField(
            title: Localizations.name,
            text: store.binding(
                get: \.name,
                send: AddEditSendItemAction.nameChanged
            ),
            footer: Localizations.nameInfo,
            accessibilityIdentifier: "SendNameEntry"
        )
    }

    /// Additional options.
    @ViewBuilder private var options: some View {
        deletionDate

        expirationDate

        accessCount

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

        BitwardenMultilineTextField(
            title: Localizations.notes,
            text: store.binding(
                get: \.notes,
                send: AddEditSendItemAction.notesChanged
            ),
            footer: Localizations.notesInfo
        )

        Toggle(Localizations.hideEmail, isOn: store.binding(
            get: \.isHideMyEmailOn,
            send: AddEditSendItemAction.hideMyEmailChanged
        ))
        .toggleStyle(.bitwarden)
        .accessibilityIdentifier("SendHideEmailSwitch")
        .disabled(!store.state.isHideMyEmailOn && store.state.isSendHideEmailDisabled)

        Toggle(Localizations.disableSend, isOn: store.binding(
            get: \.isDeactivateThisSendOn,
            send: AddEditSendItemAction.deactivateThisSendChanged
        ))
        .toggleStyle(.bitwarden)
        .accessibilityIdentifier("SendDeactivateSwitch")
    }

    /// The options button.
    @ViewBuilder private var optionsButton: some View {
        Button {
            store.send(.optionsPressed)
        } label: {
            HStack(spacing: 8) {
                Text(Localizations.options)
                    .styleGuide(.body)

                Asset.Images.downAngle.swiftUIImage
                    .imageStyle(.accessoryIcon)
                    .rotationEffect(store.state.isOptionsExpanded ? Angle(degrees: 180) : .zero)
            }
            .padding(.vertical, 12)
            .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)
        }
        .accessibilityIdentifier("SendShowHideOptionsButton")
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

    /// The save button.
    @ViewBuilder private var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.savePressed)
        }
        .accessibilityIdentifier("SaveButton")
        .buttonStyle(.primary())
    }

    /// The attributes for a text type send.
    @ViewBuilder private var textSendAttributes: some View {
        BitwardenMultilineTextField(
            title: Localizations.text,
            text: store.binding(
                get: \.text,
                send: AddEditSendItemAction.textChanged
            ),
            footer: Localizations.typeTextInfo,
            accessibilityIdentifier: "SendTextContentEntry"
        )

        Toggle(Localizations.hideTextByDefault, isOn: store.binding(
            get: \.isHideTextByDefaultOn,
            send: AddEditSendItemAction.hideTextByDefaultChanged
        ))
        .toggleStyle(.bitwarden)
        .accessibilityIdentifier("SendHideTextByDefaultToggle")
    }

    /// The type field.
    @ViewBuilder private var typePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localizations.type)
                .styleGuide(.subheadline, weight: .semibold)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

            Picker(Localizations.type, selection: store.binding(
                get: \.type,
                send: AddEditSendItemAction.typeChanged
            )) {
                ForEach(SendType.allCases, id: \.self) { sendType in
                    Text(sendType.localizedName)
                        .tag(sendType)
                        .accessibilityIdentifier(sendType == .file ? "SendFileButton" : "SendTextButton")
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
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

#Preview("Options - Custom Dates") {
    NavigationView {
        AddEditSendItemView(
            store: Store(
                processor: StateProcessor(
                    state: AddEditSendItemState(
                        deletionDate: .custom,
                        expirationDate: .custom,
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
                        customExpirationDate: nil,
                        deletionDate: .custom,
                        expirationDate: .custom,
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
                        customExpirationDate: nil,
                        deletionDate: .custom,
                        expirationDate: .custom,
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
#endif // swiftlint:disable:this file_length
