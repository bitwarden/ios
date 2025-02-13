import SwiftUI

// MARK: - AddEditItemView

/// A view that allows the user to add or edit a cipher to a vault.
///
struct AddEditLoginItemView: View {
    // MARK: Types

    /// The focusable fields in a login view.
    enum FocusedField: Int, Hashable {
        case userName
        case password
        case totp
    }

    // MARK: Properties

    /// The currently focused field.
    @FocusState private var focusedField: FocusedField?

    /// The `Store` for this view.
    @ObservedObject var store: Store<LoginItemState, AddEditItemAction, AddEditItemEffect>

    /// The closure to call when the fields are rendered for the guided tour.
    var didRenderFrame: ((GuidedTourStep, CGRect) -> Void)?

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                ContentBlock {
                    usernameField

                    passwordField

                    fidoField
                }

                totpView
                    .guidedTourStep(.step2) { frame in
                        didRenderFrame?(.step2, frame)
                    }
            }

            uriSection
        }
    }

    // MARK: Private views

    /// The fido passkey field.
    @ViewBuilder var fidoField: some View {
        if let fido2Credential = store.state.fido2Credentials.first {
            BitwardenTextValueField(
                title: Localizations.passkey,
                value: Localizations.createdXY(
                    fido2Credential.creationDate.formatted(date: .numeric, time: .omitted),
                    fido2Credential.creationDate.formatted(date: .omitted, time: .shortened)
                )
            ) {
                if store.state.canViewPassword, store.state.editView {
                    AccessoryButton(
                        asset: Asset.Images.minusCircle24,
                        accessibilityLabel: Localizations.removePasskey
                    ) {
                        store.send(.removePasskeyPressed)
                    }
                    .accessibilityIdentifier("LoginRemovePasskeyButton")
                }
            }
        }
    }

    /// The password field.
    private var passwordField: some View {
        BitwardenTextField(
            title: Localizations.password,
            text: store.binding(
                get: \.password,
                send: AddEditItemAction.passwordChanged
            ),
            accessibilityIdentifier: "LoginPasswordEntry",
            passwordVisibilityAccessibilityId: "ViewPasswordButton",
            canViewPassword: store.state.canViewPassword,
            isPasswordVisible: store.binding(
                get: \.isPasswordVisible,
                send: AddEditItemAction.togglePasswordVisibilityChanged
            )
        ) {
            if store.state.canViewPassword {
                AccessoryButton(asset: Asset.Images.generate24, accessibilityLabel: Localizations.generatePassword) {
                    store.send(.generatePasswordPressed)
                }
                .guidedTourStep(.step1) { frame in
                    didRenderFrame?(.step1, frame)
                }
                .accessibilityIdentifier("RegeneratePasswordButton")
            }
        } footerContent: {
            if store.state.canViewPassword {
                AsyncButton(Localizations.checkPasswordForDataBreaches) {
                    await store.perform(.checkPasswordPressed)
                }
                .accessibilityIdentifier("CheckPasswordButton")
                .buttonStyle(.bitwardenBorderless)
                .padding(.vertical, 14)
            }
        }
        .disabled(!store.state.canViewPassword)
        .textFieldConfiguration(.password)
        .focused($focusedField, equals: .password)
        .onSubmit { focusNextField($focusedField) }
    }

    /// The view for TOTP authenticator key.
    @ViewBuilder private var totpView: some View {
        if store.state.canViewPassword {
            BitwardenTextField(
                title: Localizations.authenticatorKey,
                text: store.binding(
                    get: \.authenticatorKey,
                    send: AddEditItemAction.totpKeyChanged
                ),
                accessibilityIdentifier: "LoginTotpEntry",
                canViewPassword: store.state.canViewPassword,
                isPasswordVisible: store.binding(
                    get: \.isAuthKeyVisible,
                    send: AddEditItemAction.authKeyVisibilityTapped
                ),
                trailingContent: {
                    if !store.state.authenticatorKey.isEmpty {
                        AccessoryButton(asset: Asset.Images.copy24, accessibilityLabel: Localizations.copyTotp) {
                            await store.perform(.copyTotpPressed)
                        }
                    }
                },
                footerContent: {
                    AsyncButton {
                        await store.perform(.setupTotpPressed)
                    } label: {
                        Label(Localizations.setUpAuthenticatorKey, image: Asset.Images.camera16.swiftUIImage)
                    }
                    .accessibilityIdentifier("SetupTotpButton")
                    .buttonStyle(.bitwardenBorderless)
                    .padding(.vertical, 14)
                }
            )
            .disabled(!store.state.canViewPassword)
            .focused($focusedField, equals: .totp)
            .onSubmit {
                store.send(.totpFieldLeftFocus)
                focusNextField($focusedField)
            }
        } else {
            BitwardenField(title: Localizations.authenticatorKey) {
                PasswordText(password: store.state.authenticatorKey, isPasswordVisible: false)
            }
        }
    }

    /// The section for uris.
    @ViewBuilder private var uriSection: some View {
        SectionView(Localizations.autofillOptions, contentSpacing: 8) {
            ContentBlock {
                ForEachIndexed(store.state.uris) { index, uriState in
                    BitwardenTextField(
                        title: Localizations.websiteURI,
                        text: store.binding(
                            get: { _ in uriState.uri },
                            send: { AddEditItemAction.uriChanged($0, index: index) }
                        ),
                        accessibilityIdentifier: "LoginUriEntry"
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
                            Asset.Images.cog24.swiftUIImage
                                .imageStyle(.accessoryIcon24)
                        }
                        .accessibilityIdentifier("LoginUriOptionsButton")
                    }
                    .textFieldConfiguration(.url)
                }

                Button {
                    withAnimation {
                        store.send(.newUriPressed)
                    }
                } label: {
                    Label(Localizations.addWebsite, image: Asset.Images.plus16.swiftUIImage)
                }
                .accessibilityIdentifier("LoginAddNewUriButton")
                .buttonStyle(.bitwardenBorderless)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            }
            .guidedTourStep(.step3) { frame in
                didRenderFrame?(.step3, frame)
            }
        }
    }

    /// The username field.
    private var usernameField: some View {
        BitwardenTextField(
            title: Localizations.username,
            text: store.binding(
                get: \.username,
                send: AddEditItemAction.usernameChanged
            ),
            accessibilityIdentifier: "LoginUsernameEntry"
        ) {
            AccessoryButton(
                asset: Asset.Images.generate24,
                accessibilityLabel: Localizations.generateUsername
            ) {
                store.send(.generateUsernamePressed)
            }
            .accessibilityIdentifier("GenerateUsernameButton")
        }
        .textFieldConfiguration(.username)
        .focused($focusedField, equals: .userName)
        .onSubmit { focusNextField($focusedField) }
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
                                state: LoginItemState(
                                    isTOTPAvailable: false,
                                    totpState: .none
                                )
                            )
                        )
                    )
                }
                .padding(16)
            }
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
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
                                    isTOTPAvailable: true,
                                    totpState: .init(key)
                                )
                            )
                        )
                    )
                }
                .padding(16)
            }
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            .ignoresSafeArea()
        }
        .previewDisplayName("Auth Key")
    }
}
#endif
