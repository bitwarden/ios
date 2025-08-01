import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - EditAuthenticatorItemView

/// A view for editing an item
struct EditAuthenticatorItemView: View {
    // MARK: Properties

    @ObservedObject var store: Store<
        EditAuthenticatorItemState,
        EditAuthenticatorItemAction,
        EditAuthenticatorItemEffect
    >

    // MARK: View

    var body: some View {
        content
            .navigationTitle(Localizations.editItem)
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismissPressed)
                }
            }
            .task { await store.perform(.appeared) }
            .toast(store.binding(
                get: \.toast,
                send: EditAuthenticatorItemAction.toastShown
            ))
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                informationSection

                advancedButton
                if store.state.isAdvancedExpanded {
                    advancedOptions
                }

                saveButton

                deleteButton
            }
            .padding(16)
        }
        .dismissKeyboardImmediately()
        .background(
            Asset.Colors.backgroundSecondary.swiftUIColor
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var informationSection: some View {
        SectionView(Localizations.itemInformation) {
            BitwardenTextField(
                title: Localizations.name,
                text: store.binding(
                    get: \.issuer,
                    send: EditAuthenticatorItemAction.issuerChanged
                )
            )
            .accessibilityIdentifier("EditItemNameField")

            BitwardenTextField(
                title: Localizations.key,
                text: store.binding(
                    get: \.secret,
                    send: EditAuthenticatorItemAction.secretChanged
                ),
                accessibilityIdentifier: "EditItemKeyField",
                passwordVisibilityAccessibilityId: "EditKeyVisibilityToggle",
                isPasswordVisible: store.binding(
                    get: \.isSecretVisible,
                    send: EditAuthenticatorItemAction.toggleSecretVisibilityChanged
                )
            )
            .textFieldConfiguration(.password)

            BitwardenTextField(
                title: Localizations.username,
                text: store.binding(
                    get: \.accountName,
                    send: EditAuthenticatorItemAction.accountNameChanged
                )
            )
            .textFieldConfiguration(.username)
            .accessibilityIdentifier("EditItemUsernameField")

            Toggle(Localizations.favorite, isOn: store.binding(
                get: \.isFavorited,
                send: EditAuthenticatorItemAction.favoriteChanged
            ))
            .toggleStyle(.bitwarden)
            .accessibilityIdentifier("EditItemFavoriteToggle")
        }
    }

    private var advancedButton: some View {
        Button {
            store.send(.advancedPressed)
        } label: {
            HStack(spacing: 8) {
                Text(Localizations.advanced)
                    .styleGuide(.body)

                Asset.Images.downAngle.swiftUIImage
                    .imageStyle(.accessoryIcon)
                    .rotationEffect(store.state.isAdvancedExpanded ? Angle(degrees: 180) : .zero)
            }
            .padding(.vertical, 12)
            .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)
        }
        .accessibilityIdentifier("EditShowHideAdvancedButton")
    }

    @ViewBuilder private var advancedOptions: some View {
        BitwardenMenuField(
            title: Localizations.otpType,
            options: TotpTypeOptions.allCases,
            selection: store.binding(
                get: \.totpType,
                send: EditAuthenticatorItemAction.totpTypeChanged
            )
        )

        if store.state.totpType == .totp {
            BitwardenMenuField(
                title: Localizations.algorithm,
                options: TOTPCryptoHashAlgorithm.allCases,
                selection: store.binding(
                    get: \.algorithm,
                    send: EditAuthenticatorItemAction.algorithmChanged
                )
            )

            BitwardenMenuField(
                title: Localizations.refreshPeriod,
                options: TotpPeriodOptions.allCases,
                selection: store.binding(
                    get: \.period,
                    send: EditAuthenticatorItemAction.periodChanged
                )
            )

            StepperFieldView(
                field: StepperField<EditAuthenticatorItemState>(
                    accessibilityId: nil,
                    keyPath: \.digits,
                    range: 5 ... 10,
                    title: Localizations.numberOfDigits,
                    value: store.state.digits
                ),
                action: { newValue in
                    store.send(.digitsChanged(newValue))
                }
            )
        }

        Divider()
    }

    private var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.savePressed)
        }
        .accessibilityIdentifier("EditItemSaveButton")
        .buttonStyle(.primary())
    }

    private var deleteButton: some View {
        AsyncButton(Localizations.delete) {
            await store.perform(.deletePressed)
        }
        .accessibilityIdentifier("EditItemDeleteButton")
        .buttonStyle(.tertiary(isDestructive: true))
    }
}

// MARK: - EditAuthenticatorItemView_Previews

#if DEBUG
struct EditAuthenticatorItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditAuthenticatorItemView(
                store: Store(
                    processor: StateProcessor(
                        state: AuthenticatorItemState(
                            accountName: "Account",
                            algorithm: .sha1,
                            configuration: .existing(
                                authenticatorItemView: AuthenticatorItemView.fixture()
                            ),
                            digits: 6,
                            id: "1",
                            isFavorited: false,
                            issuer: "Issuer",
                            name: "Example",
                            period: .thirty,
                            secret: "example",
                            totpState: LoginTOTPState(
                                authKeyModel: TOTPKeyModel(authenticatorKey: "example")!,
                                codeModel: TOTPCodeModel(
                                    code: "123456",
                                    codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                                    period: 30
                                )
                            ),
                            totpType: .totp
                        )
                        .editState
                    )
                )
            )
        }.previewDisplayName("Advanced Closed")

        NavigationView {
            EditAuthenticatorItemView(
                store: Store(
                    processor: StateProcessor(
                        state: AuthenticatorItemState(
                            accountName: "Account",
                            algorithm: .sha1,
                            configuration: .existing(
                                authenticatorItemView: AuthenticatorItemView.fixture()
                            ),
                            digits: 6,
                            id: "1",
                            isAdvancedExpanded: true,
                            isFavorited: false,
                            issuer: "Issuer",
                            name: "Example",
                            period: .thirty,
                            secret: "example",
                            totpState: LoginTOTPState(
                                authKeyModel: TOTPKeyModel(authenticatorKey: "example")!,
                                codeModel: TOTPCodeModel(
                                    code: "123456",
                                    codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                                    period: 30
                                )
                            ),
                            totpType: .totp
                        )
                        .editState
                    )
                )
            )
        }.previewDisplayName("Advanced Open, TOTP")

        NavigationView {
            EditAuthenticatorItemView(
                store: Store(
                    processor: StateProcessor(
                        state: AuthenticatorItemState(
                            accountName: "Account",
                            algorithm: .sha1,
                            configuration: .existing(
                                authenticatorItemView: AuthenticatorItemView.fixture()
                            ),
                            digits: 6,
                            id: "1",
                            isAdvancedExpanded: true,
                            isFavorited: false,
                            issuer: "Issuer",
                            name: "Example",
                            period: .thirty,
                            secret: "example",
                            totpState: LoginTOTPState(
                                authKeyModel: TOTPKeyModel(authenticatorKey: "example")!,
                                codeModel: TOTPCodeModel(
                                    code: "123456",
                                    codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                                    period: 30
                                )
                            ),
                            totpType: .steam
                        )
                        .editState
                    )
                )
            )
        }.previewDisplayName("Advanced Open, Steam")
    }
}
#endif
