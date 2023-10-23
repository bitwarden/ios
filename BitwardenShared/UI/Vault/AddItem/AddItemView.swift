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
                section(title: Localizations.itemInformation) {
                    BitwardenMenuField(
                        title: Localizations.type,
                        options: [.login, .card, .identity, .secureNote],
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
                                icon: Asset.Images.restart
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
                                icon: Asset.Images.restart
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

                        Button {
                            store.send(.setupTotpPressed)
                        } label: {
                            HStack(alignment: .center, spacing: 4) {
                                Asset.Images.camera.swiftUIImage
                                Text(Localizations.setupTotp)
                            }
                        }
                        .buttonStyle(.tertiary())
                    }
                }

                section(title: Localizations.urIs) {
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
                }

                section(title: Localizations.miscellaneous) {
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

                section(title: Localizations.notes) {
                    BitwardenTextField(
                        text: store.binding(
                            get: \.notes,
                            send: AddItemAction.notesChanged
                        )
                    )
                    .accessibilityLabel(Localizations.notes)
                }

                section(title: Localizations.customFields) {
                    Button(Localizations.newCustomField) {
                        store.send(.newCustomFieldPressed)
                    }
                    .buttonStyle(.tertiary())
                }

                section(title: Localizations.ownership) {
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
                Button {
                    store.send(.dismissPressed)
                } label: {
                    Label {
                        Text(Localizations.cancel)
                    } icon: {
                        Image(asset: Asset.Images.cancel)
                            .resizable()
                            .foregroundColor(Color(asset: Asset.Colors.primaryBitwarden))
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
    }

    // MARK: Methods

    /// Creates a section with a title hosted in a title view.
    ///
    /// - Parameters:
    ///   - title: The title of this section.
    ///   - content: The content to place below the title view in this section.
    ///
    @ViewBuilder
    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

            content()
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
