import SwiftUI

// MARK: - AddItemView

/// A view that allows the user to add a new item to a vault.
///
struct AddItemView: View {
    // MARK: Private Properties

    /// An object used to open urls in this view.
    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddItemState, AddItemAction, AddItemEffect>

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                VaultItemSectionView(title: Localizations.itemInformation) {
                    BitwardenMenuField(
                        title: Localizations.type,
                        options: CipherType.allCases,
                        selection: store.binding(
                            get: \.type,
                            send: AddItemAction.typeChanged
                        )
                    )

                    BitwardenTextField(
                        title: Localizations.name,
                        text: store.binding(
                            get: \.name,
                            send: AddItemAction.nameChanged
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
                            get: \.username,
                            send: AddItemAction.usernameChanged
                        )
                    )
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

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
                            send: AddItemAction.togglePasswordVisibilityChanged
                        ),
                        text: store.binding(
                            get: \.password,
                            send: AddItemAction.passwordChanged
                        )
                    )
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)

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

                VaultItemSectionView(title: Localizations.urIs) {
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
                            get: \.uri,
                            send: AddItemAction.uriChanged
                        )
                    )
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .textContentType(.URL)

                    Button(Localizations.newUri) {
                        store.send(.newUriPressed)
                    }
                    .buttonStyle(.tertiary())
                }

                VaultItemSectionView(title: Localizations.miscellaneous) {
                    BitwardenTextField(
                        title: Localizations.folder,
                        text: store.binding(
                            get: \.folder,
                            send: AddItemAction.folderChanged
                        )
                    )

                    Toggle(Localizations.favorite, isOn: store.binding(
                        get: \.isFavoriteOn,
                        send: AddItemAction.favoriteChanged
                    ))
                    .toggleStyle(.bitwarden)

                    Toggle(isOn: store.binding(
                        get: \.isMasterPasswordRePromptOn,
                        send: AddItemAction.masterPasswordRePromptChanged
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

                VaultItemSectionView(title: Localizations.notes) {
                    BitwardenTextField(
                        text: store.binding(
                            get: \.notes,
                            send: AddItemAction.notesChanged
                        )
                    )
                    .accessibilityLabel(Localizations.notes)
                }

                VaultItemSectionView(title: Localizations.customFields) {
                    Button(Localizations.newCustomField) {
                        store.send(.newCustomFieldPressed)
                    }
                    .buttonStyle(.tertiary())
                }

                VaultItemSectionView(title: Localizations.ownership) {
                    BitwardenTextField(
                        title: Localizations.whoOwnsThisItem,
                        text: store.binding(
                            get: \.owner,
                            send: AddItemAction.ownerChanged
                        )
                    )
                }

                AsyncButton(Localizations.save) {
                    await store.perform(.savePressed)
                }
                .buttonStyle(.primary())
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(Localizations.addItem)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ToolbarButton(asset: Asset.Images.cancel, label: Localizations.cancel) {
                    store.send(.dismissPressed)
                }
            }
        }
    }
}

struct AddItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddItemView(
                store: Store(
                    processor: StateProcessor(
                        state: AddItemState()
                    )
                )
            )
        }
        .previewDisplayName("Empty")
    }
}
