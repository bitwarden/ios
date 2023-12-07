import SwiftUI

// MARK: - AddEditItemView

/// A view that allows the user to add or edit a cipher to a vault.
///
struct AddEditLoginItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<LoginItemState, AddEditItemAction, AddEditItemEffect>

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
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
                    send: AddEditItemAction.usernameChanged
                )
            )
            .textFieldConfiguration(.username)
        }

        BitwardenTextField(
            title: Localizations.password,
            buttons: [
                .init(
                    accessibilityLabel: Localizations.checkPassword,
                    action: {
                        await store.perform(.checkPasswordPressed)
                    },
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
                get: \.password,
                send: AddEditItemAction.passwordChanged
            )
        )
        .textFieldConfiguration(.password)

        VStack(alignment: .leading, spacing: 8) {
            Text(Localizations.authenticatorKey)
                .styleGuide(.subheadline, weight: .semibold)
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
    }

    var uriSection: some View {
        SectionView(Localizations.urIs) {
            ForEachIndexed(store.state.uris, id: \.self) { index, uriView in
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
                .textFieldConfiguration(.url)
            }

            Button(Localizations.newUri) {
                store.send(.newUriPressed)
            }
            .buttonStyle(.tertiary())
        }
    }
}

// MARK: Previews

#if DEBUG
struct AddEditLoginItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    AddEditLoginItemView(
                        store: Store(
                            processor: StateProcessor(
                                state: LoginItemState()
                            )
                        )
                    )
                }
                .padding(16)
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .ignoresSafeArea()
        }
        .previewDisplayName("Empty Add Edit State")
    }
}
#endif
