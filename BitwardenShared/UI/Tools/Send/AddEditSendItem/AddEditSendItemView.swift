import SwiftUI

// MARK: - AddEditSendItemView

/// A view that allows the user to add or edit a send item.
///
struct AddEditSendItemView: View { // swiftlint:disable:this type_body_length
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
        .animation(.easeInOut(duration: 0.2), value: store.state.type)
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
                AccessibleHStack(alignment: .leading, spacing: 8) {
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
                AccessibleHStack(alignment: .leading, spacing: 8) {
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
        VStack(alignment: .leading, spacing: 16) {
            Text(Localizations.file)
                .styleGuide(.subheadline, weight: .semibold)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

            HStack(spacing: 0) {
                Spacer()

                Text(store.state.fileName ?? Localizations.noFileChosen)
                    .styleGuide(.callout)
                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Menu {
                    Button(Localizations.photos) {
                        store.send(.photosPressed)
                    }
                    Button(Localizations.camera) {
                        store.send(.cameraPressed)
                    }
                    Button(Localizations.browse) {
                        store.send(.browsePressed)
                    }
                } label: {
                    Text(Localizations.chooseFile)
                        .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(Asset.Colors.fillTertiary.swiftUIColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text(Localizations.maxFileSize)
                    .styleGuide(.subheadline)
                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
            }

            Text(Localizations.typeFileInfo)
                .styleGuide(.footnote)
                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
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
            footer: Localizations.nameInfo
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
            text: store.binding(
                get: \.password,
                send: AddEditSendItemAction.passwordChanged
            ),
            footer: Localizations.passwordInfo,
            isPasswordVisible: store.binding(
                get: \.isPasswordVisible,
                send: AddEditSendItemAction.passwordVisibileChanged
            )
        )
        .textFieldConfiguration(.password)

        BitwardenTextField(
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
            text: store.binding(
                get: \.text,
                send: AddEditSendItemAction.textChanged
            ),
            footer: Localizations.typeTextInfo
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
                        isShareOnSaveOn: true,
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
                        isShareOnSaveOn: true,
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
} // swiftlint:disable:this file_length
#endif
