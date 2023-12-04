import SwiftUI

// MARK: - AddEditItemView

/// A view that allows the user to add a new item to a vault.
///
struct AddEditItemView: View {
    // MARK: Private Properties

    /// An object used to open urls in this view.
    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddEditItemState, AddEditItemAction, AddEditItemEffect>

    var body: some View {
        switch store.state.configuration {
        case .add:
            addView
        case .edit:
            editView
        }
    }

    private var addView: some View {
        content
            .navigationTitle(Localizations.addItem)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ToolbarButton(asset: Asset.Images.cancel, label: Localizations.cancel) {
                        store.send(.dismissPressed)
                    }
                }
            }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                informationSection
                uriSection
                miscellaneousSection
                notesSection
                customSection
                ownershipSection
                saveButton
            }
            .padding(16)
        }
        .background(
            Asset.Colors.backgroundSecondary.swiftUIColor
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var customSection: some View {
        VaultItemSectionView(title: Localizations.customFields) {
            Button(Localizations.newCustomField) {
                store.send(.newCustomFieldPressed)
            }
            .buttonStyle(.tertiary())
        }
    }

    private var editView: some View {
        NavigationView {
            content
                .navigationTitle(Localizations.editItem)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            store.send(.morePressed)
                        } label: {
                            Asset.Images.verticalKabob.swiftUIImage
                                .resizable()
                                .frame(width: 19, height: 19)
                        }
                        .accessibilityLabel(Localizations.options)
                        Button {
                            store.send(.dismissPressed)
                        } label: {
                            Asset.Images.cancel.swiftUIImage
                                .resizable()
                                .frame(width: 19, height: 19)
                        }
                        .accessibilityLabel(Localizations.close)
                    }
                }
        }
    }

    private var informationSection: some View {
        VaultItemSectionView(title: Localizations.itemInformation) {
            BitwardenMenuField(
                title: Localizations.type,
                options: CipherType.allCases,
                selection: store.binding(
                    get: \.properties.type,
                    send: AddEditItemAction.typeChanged
                )
            )

            BitwardenTextField(
                title: Localizations.name,
                text: store.binding(
                    get: \.properties.name,
                    send: AddEditItemAction.nameChanged
                )
            )

            BitwardenTextField(
                title: Localizations.username,
                buttons: [
                    .init(
                        accessibilityLabel: Localizations.generateUsername,
                        action: { store.send(.generateUsernamePressed) },
                        icon: Asset.Images.restart2
                    ),
                ],
                text: store.binding(
                    get: \.properties.username,
                    send: AddEditItemAction.usernameChanged
                )
            )
            .textContentType(.username)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            passwordField

            VStack(alignment: .leading, spacing: 8) {
                Text(Localizations.authenticatorKey)
                    .font(.styleGuide(.subheadline))
                    .bold()
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

                AsyncButton {
                    await store.perform(.setupTotpPressed)
                } label: {
                    HStack(alignment: .center, spacing: 4) {
                        Asset.Images.camera.swiftUIImage
                        Text(Localizations.setupTotp)
                    }
                }
                .buttonStyle(.tertiary())
            }
        }
    }
}

private extension AddEditItemView {
    var miscellaneousSection: some View {
        VaultItemSectionView(title: Localizations.miscellaneous) {
            BitwardenTextField(
                title: Localizations.folder,
                text: store.binding(
                    get: \.properties.folder,
                    send: AddEditItemAction.folderChanged
                )
            )

            Toggle(Localizations.favorite, isOn: store.binding(
                get: \.properties.isFavoriteOn,
                send: AddEditItemAction.favoriteChanged
            ))
            .toggleStyle(.bitwarden)

            Toggle(isOn: store.binding(
                get: \.properties.isMasterPasswordRePromptOn,
                send: AddEditItemAction.masterPasswordRePromptChanged
            )) {
                HStack(alignment: .center, spacing: 4) {
                    Text(Localizations.passwordPrompt)
                    Button {
                        openURL(ExternalLinksConstants.protectIndividualItems)
                    } label: {
                        Asset.Images.questionRound.swiftUIImage
                    }
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .accessibilityLabel(Localizations.masterPasswordRePromptHelp)
                }
            }
            .toggleStyle(.bitwarden)
        }
    }

    var notesSection: some View {
        VaultItemSectionView(title: Localizations.notes) {
            BitwardenTextField(
                text: store.binding(
                    get: \.properties.notes,
                    send: AddEditItemAction.notesChanged
                )
            )
            .accessibilityLabel(Localizations.notes)
        }
    }

    var ownershipSection: some View {
        VaultItemSectionView(title: Localizations.ownership) {
            BitwardenTextField(
                title: Localizations.whoOwnsThisItem,
                text: store.binding(
                    get: \.properties.owner,
                    send: AddEditItemAction.ownerChanged
                )
            )
        }
    }

    var passwordField: some View {
        BitwardenTextField(
            title: Localizations.password,
            buttons: [
                .init(
                    accessibilityLabel: Localizations.checkPassword,
                    action: { await store.perform(.checkPasswordPressed) },
                    icon: Asset.Images.roundCheck
                ),
                .init(
                    accessibilityLabel: Localizations.generatePassword,
                    action: { store.send(.generatePasswordPressed) },
                    icon: Asset.Images.restart2
                ),
            ],
            isPasswordVisible: store.binding(
                get: \.isPasswordVisible,
                send: AddEditItemAction.togglePasswordVisibilityChanged
            ),
            text: store.binding(
                get: \.properties.password,
                send: AddEditItemAction.passwordChanged
            )
        )
        .textContentType(.password)
        .textInputAutocapitalization(.never)
    }

    var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.savePressed)
        }
        .buttonStyle(.primary())
    }

    var uriSection: some View {
        VaultItemSectionView(title: Localizations.urIs) {
            ForEach(store.state.properties.uris.indices, id: \.self) { index in
                let uriView = store.state.properties.uris[index]
                BitwardenTextField(
                    title: Localizations.uri,
                    buttons: [
                        .init(
                            accessibilityLabel: Localizations.uriMatchDetection,
                            action: { store.send(.uriSettingsPressed) },
                            icon: Asset.Images.gear
                        ),
                    ],
                    text: store.binding(
                        get: { _ in uriView.uri ?? "" },
                        send: { newValue in
                            AddEditItemAction.uriChanged(newValue, index: index)
                        }
                    )
                )
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .textContentType(.URL)
            }

            Button(Localizations.newUri) {
                store.send(.newUriPressed)
            }
            .buttonStyle(.tertiary())
        }
    }
}

struct AddItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddEditItemView(
                store: Store(
                    processor: StateProcessor(
                        state: .addItem()
                    )
                )
            )
        }
        .previewDisplayName("Empty Add")
    }
}
