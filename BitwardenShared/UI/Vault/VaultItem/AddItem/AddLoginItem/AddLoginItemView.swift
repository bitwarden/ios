import SwiftUI

// MARK: - AddItemView

/// A view that allows the user to add a new item to a vault.
///
struct AddLoginItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddLoginItemState, AddItemAction, AddItemEffect>

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
                    send: AddItemAction.usernameChanged
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
                send: AddItemAction.togglePasswordVisibilityChanged
            ),
            text: store.binding(
                get: \.password,
                send: AddItemAction.passwordChanged
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

        SectionView(Localizations.urIs) {
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
            .textFieldConfiguration(.url)

            Button(Localizations.newUri) {
                store.send(.newUriPressed)
            }
            .buttonStyle(.tertiary())
        }
    }
}

// MARK: Previews

#if DEBUG
struct AddLoginItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    AddLoginItemView(
                        store: Store(
                            processor: StateProcessor(
                                state: AddLoginItemState()
                            )
                        )
                    )
                }
                .padding(16)
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .ignoresSafeArea()
        }
        .previewDisplayName("Add Note Item")
    }
}
#endif
