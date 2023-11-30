import SwiftUI

// MARK: - EditLoginItemView

/// A view for editing the contents of a login item.
struct EditLoginItemView: View {
    // MARK: Private Properties

    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<EditLoginItemState, ViewItemAction, ViewItemEffect>

    var body: some View {
        VaultItemSectionView(title: Localizations.itemInformation) {
            BitwardenTextField(
                title: Localizations.name,
                text: store.binding(
                    get: \.properties.name,
                    send: { value in
                        ViewItemAction.editAction(.nameChanged(value))
                    }
                )
            )
            BitwardenTextField(
                title: Localizations.username,
                text: store.binding(
                    get: \.properties.username,
                    send: { value in
                        ViewItemAction.editAction(.usernameChanged(value))
                    }
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
                ],
                isPasswordVisible: store.binding(
                    get: \.isPasswordVisible,
                    send: { value in
                        ViewItemAction.editAction(.togglePasswordVisibilityChanged(value))
                    }
                ),
                text: store.binding(
                    get: \.properties.password,
                    send: { value in
                        ViewItemAction.editAction(.passwordChanged(value))
                    }
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
            uriSection
            VaultItemSectionView(title: Localizations.miscellaneous) {
                Toggle(Localizations.favorite, isOn: store.binding(
                    get: \.properties.isFavoriteOn,
                    send: { value in
                        ViewItemAction.editAction(.favoriteChanged(value))
                    }
                ))
                .toggleStyle(.bitwarden)
                Toggle(isOn: store.binding(
                    get: \.properties.isMasterPasswordRePromptOn,
                    send: { value in
                        ViewItemAction.editAction(.masterPasswordRePromptChanged(value))
                    }
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
                        get: \.properties.notes,
                        send: { value in
                            ViewItemAction.editAction(.notesChanged(value))
                        }
                    )
                )
                .accessibilityLabel(Localizations.notes)
            }
        }
    }

    private var uriSection: some View {
        VaultItemSectionView(title: Localizations.urIs) {
            ForEach(store.state.properties.uris, id: \.uri) { uriView in
                BitwardenTextField(
                    title: Localizations.uri,
                    buttons: [
                        .init(
                            accessibilityLabel: Localizations.uriMatchDetection,
                            action: { store.send(.editAction(.uriSettingsPressed)) },
                            icon: Asset.Images.gear
                        ),
                    ],
                    text: store.binding(
                        get: { _ in uriView.uri ?? "" },
                        send: { value in
                            ViewItemAction.editAction(.uriChanged(value))
                        }
                    )
                )
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .textContentType(.URL)
            }

            Button(Localizations.newUri) {
                store.send(.editAction(.newUriPressed))
            }
            .buttonStyle(.tertiary())
        }
    }
}

// MARK: - EditLoginItemAction

/// Actions that can be handled by an `ViewItemProcessor`.
enum EditLoginItemAction: Equatable {
    /// The favorite toggle was changed.
    case favoriteChanged(Bool)

    /// The master password re-prompt toggle was changed.
    case masterPasswordRePromptChanged(Bool)

    /// The name field was changed.
    case nameChanged(String)

    /// The new uri button was pressed.
    case newUriPressed

    /// The notes field was changed.
    case notesChanged(String)

    /// The password field was changed.
    case passwordChanged(String)

    /// The toggle password visibility button was changed.
    case togglePasswordVisibilityChanged(Bool)

    /// The uri field was changed.
    case uriChanged(String)

    /// The uri settings button was pressed.
    case uriSettingsPressed

    /// The username field was changed.
    case usernameChanged(String)
}

// MARK: - EditLoginItemState

struct EditLoginItemState: Equatable {
    /// A flag for password visibility.
    var isPasswordVisible: Bool

    /// The editable properties.
    var properties: VaultCipherItemProperties
}
