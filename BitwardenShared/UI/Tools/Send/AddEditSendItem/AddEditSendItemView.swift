import SwiftUI

// MARK: - AddEditSendItemView

/// A view that allows the user to add or edit a send item.
///
struct AddEditSendItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddEditSendItemState, AddEditSendItemAction, AddEditSendItemEffect>

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                nameField

                typePicker

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
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationBar(title: Localizations.addSend, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismissPressed)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.state.type)
        .animation(.easeInOut(duration: 0.2), value: store.state.deletionDate)
        .animation(.easeInOut(duration: 0.2), value: store.state.expirationDate)
        .animation(.default, value: store.state.isOptionsExpanded)
    }

    /// The deletion date field.
    @ViewBuilder private var deletionDate: some View {
        VStack(alignment: .leading, spacing: 8) {
            BitwardenMenuField(
                title: Localizations.deletionDate,
                options: SendDeletionDateType.allCases,
                selection: store.binding(
                    get: \.deletionDate,
                    send: AddEditSendItemAction.deletionDateChanged
                )
            )

            if store.state.deletionDate == .custom {
                HStack(spacing: 8) {
                    BitwardenDatePicker(
                        selection: store.binding(
                            get: \.customDeletionDate,
                            send: AddEditSendItemAction.customDeletionDateChanged
                        ),
                        displayComponents: .date
                    )

                    BitwardenDatePicker(
                        selection: store.binding(
                            get: \.customDeletionDate,
                            send: AddEditSendItemAction.customDeletionDateChanged
                        ),
                        displayComponents: .hourAndMinute
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
            BitwardenMenuField(
                title: Localizations.expirationDate,
                options: SendExpirationDateType.allCases,
                selection: store.binding(
                    get: \.expirationDate,
                    send: AddEditSendItemAction.expirationDateChanged
                )
            )

            if store.state.expirationDate == .custom {
                HStack(spacing: 8) {
                    BitwardenDatePicker(
                        selection: store.binding(
                            get: \.customExpirationDate,
                            send: AddEditSendItemAction.customExpirationDateChanged
                        ),
                        displayComponents: .date
                    )

                    BitwardenDatePicker(
                        selection: store.binding(
                            get: \.customExpirationDate,
                            send: AddEditSendItemAction.customExpirationDateChanged
                        ),
                        displayComponents: .hourAndMinute
                    )
                }
            }

            Text(Localizations.expirationDateInfo)
                .styleGuide(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
        }
    }

    /// The attributes for a file type send.
    @ViewBuilder private var fileSendAttributes: some View {
        // TODO: BIT-1255 Add the UI for file sends
        Text("File Send Attributes")
    }

    /// The name field.
    @ViewBuilder private var nameField: some View {
        BitwardenTextField(
            title: Localizations.name,
            footer: Localizations.nameInfo,
            text: store.binding(
                get: \.name,
                send: AddEditSendItemAction.nameChanged
            )
        )
    }

    /// Additional options.
    @ViewBuilder private var options: some View {
        deletionDate

        expirationDate

        VStack(alignment: .leading, spacing: 8) {
            Stepper(
                value: store.binding(
                    get: \.maximumAccessCount,
                    send: AddEditSendItemAction.maximumAccessCountChanged
                ),
                in: 0 ... Int.max
            ) {
                HStack(spacing: 8) {
                    Text(Localizations.maximumAccessCount)
                        .styleGuide(.body)
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)

                    Spacer()

                    if store.state.maximumAccessCount > 0 {
                        Text("\(store.state.maximumAccessCount)")
                            .styleGuide(.body, monoSpacedDigit: true)
                            .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                    }
                }
            }

            Divider()

            Text(Localizations.maximumAccessCountInfo)
                .styleGuide(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
        }

        BitwardenTextField(
            title: Localizations.newPassword,
            footer: Localizations.passwordInfo,
            isPasswordVisible: store.binding(
                get: \.isPasswordVisible,
                send: AddEditSendItemAction.passwordVisibileChanged
            ),
            text: store.binding(
                get: \.password,
                send: AddEditSendItemAction.passwordChanged
            )
        )
        .textFieldConfiguration(.password)

        BitwardenTextField(
            title: Localizations.notes,
            footer: Localizations.notesInfo,
            text: store.binding(
                get: \.notes,
                send: AddEditSendItemAction.notesChanged
            )
        )

        Toggle(Localizations.hideEmail, isOn: store.binding(
            get: \.isHideMyEmailOn,
            send: AddEditSendItemAction.hideMyEmailChanged
        ))
        .toggleStyle(.bitwarden)

        Toggle(Localizations.disableSend, isOn: store.binding(
            get: \.isDeactivateThisSendOn,
            send: AddEditSendItemAction.deactivateThisSendChanged
        ))
        .toggleStyle(.bitwarden)
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
                    .resizable()
                    .frame(width: 16, height: 16)
                    .rotationEffect(store.state.isOptionsExpanded ? Angle(degrees: 180) : .zero)
            }
            .padding(.vertical, 12)
            .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)
        }
    }

    /// The save button.
    @ViewBuilder private var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.savePressed)
        }
        .buttonStyle(.primary())
    }

    /// The attributes for a text type send.
    @ViewBuilder private var textSendAttributes: some View {
        BitwardenTextField(
            title: Localizations.text,
            footer: Localizations.typeTextInfo,
            text: store.binding(
                get: \.text,
                send: AddEditSendItemAction.textChanged
            )
        )

        Toggle(Localizations.hideTextByDefault, isOn: store.binding(
            get: \.isHideTextByDefaultOn,
            send: AddEditSendItemAction.hideTextByDefaultChanged
        ))
        .toggleStyle(.bitwarden)

        Toggle(Localizations.shareOnSave, isOn: store.binding(
            get: \.isShareOnSaveOn,
            send: AddEditSendItemAction.shareOnSaveChanged
        ))
        .toggleStyle(.bitwarden)
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
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

// MARK: Previews

struct AddSendItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddEditSendItemView(
                store: Store(
                    processor: StateProcessor(
                        state: AddEditSendItemState()
                    )
                )
            )
        }
        .previewDisplayName("Empty")

        NavigationView {
            AddEditSendItemView(
                store: Store(
                    processor: StateProcessor(
                        state: AddEditSendItemState(
                            isHideTextByDefaultOn: true,
                            isShareOnSaveOn: true,
                            name: "Sendy",
                            text: "Example text",
                            type: .text
                        )
                    )
                )
            )
        }
        .previewDisplayName("Text")

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
        .previewDisplayName("Options")

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
        .previewDisplayName("Options - Custom Dates")
    }
}
