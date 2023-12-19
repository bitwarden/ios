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
                text: store.binding(
                    get: \.username,
                    send: AddEditItemAction.usernameChanged
                )
            ) {
                AccessoryButton(asset: Asset.Images.restart2, accessibilityLabel: Localizations.generateUsername) {
                    store.send(.generateUsernamePressed)
                }
            }
            .textFieldConfiguration(.username)
        }

        BitwardenTextField(
            title: Localizations.password,
            isPasswordVisible: store.binding(
                get: \.isPasswordVisible,
                send: AddEditItemAction.togglePasswordVisibilityChanged
            ),
            text: store.binding(
                get: \.password,
                send: AddEditItemAction.passwordChanged
            )
        ) {
            AccessoryButton(asset: Asset.Images.roundCheck, accessibilityLabel: Localizations.checkPassword) {
                await store.perform(.checkPasswordPressed)
            }
            AccessoryButton(asset: Asset.Images.restart2, accessibilityLabel: Localizations.generatePassword) {
                store.send(.generatePasswordPressed)
            }
        }
        .textFieldConfiguration(.password)

        totpView

        uriSection
    }

    /// The view for TOTP authenticator key..
    @ViewBuilder private var totpView: some View {
        if let key = store.state.authenticatorKey,
           !key.isEmpty {
            BitwardenTextField(
                title: Localizations.authenticatorKey,
                text: store.binding(
                    get: { _ in key },
                    send: AddEditItemAction.totpKeyChanged
                ),
                trailingContent: {
                    AccessoryButton(asset: Asset.Images.copy, accessibilityLabel: Localizations.copyTotp) {
                        await store.perform(.copyTotpPressed)
                    }
                    AccessoryButton(asset: Asset.Images.camera, accessibilityLabel: Localizations.setupTotp) {
                        await store.perform(.setupTotpPressed)
                    }
                }
            )
        } else {
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
        }
    }

    /// The section for uris.
    @ViewBuilder private var uriSection: some View {
        SectionView(Localizations.urIs) {
            ForEachIndexed(store.state.uris) { index, uriState in
                BitwardenTextField(
                    title: Localizations.uri,
                    text: store.binding(
                        get: { _ in uriState.uri },
                        send: { AddEditItemAction.uriChanged($0, index: index) }
                    )
                ) {
                    Menu {
                        Menu(Localizations.matchDetection) {
                            Picker(Localizations.matchDetection, selection: store.binding(
                                get: { _ in uriState.matchType },
                                send: { .uriTypeChanged($0, index: index) }
                            )) {
                                ForEach(DefaultableType<UriMatchType>.allCases, id: \.hashValue) { option in
                                    Text(option.localizedName).tag(option)
                                }
                            }
                        }
                        Button(Localizations.remove, role: .destructive) {
                            withAnimation {
                                store.send(.removeUriPressed(index: index))
                            }
                        }
                    } label: {
                        Asset.Images.gear.swiftUIImage
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }
                .textFieldConfiguration(.url)
            }

            Button(Localizations.newUri) {
                withAnimation {
                    store.send(.newUriPressed)
                }
            }
            .buttonStyle(.tertiary())
        }
    }
}

// MARK: Previews

#if DEBUG
struct AddEditLoginItemView_Previews: PreviewProvider {
    // swiftlint:disable:next line_length
    static let key = "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA1&digits=6&period=30"

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

        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    AddEditLoginItemView(
                        store: Store(
                            processor: StateProcessor(
                                state: LoginItemState(
                                    totpKey: .init(authenticatorKey: key)
                                )
                            )
                        )
                    )
                }
                .padding(16)
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .ignoresSafeArea()
        }
        .previewDisplayName("Auth Key")
    }
}
#endif
