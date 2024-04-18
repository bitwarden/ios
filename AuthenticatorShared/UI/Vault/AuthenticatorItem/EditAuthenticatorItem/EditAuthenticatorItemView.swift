import BitwardenSdk
import SwiftUI

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
                    get: \.name,
                    send: EditAuthenticatorItemAction.nameChanged
                )
            )

            BitwardenTextField(
                title: Localizations.authenticatorKey,
                text: store.binding(
                    get: \.secret,
                    send: EditAuthenticatorItemAction.secretChanged
                ),
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

            BitwardenTextField(
                title: Localizations.issuer,
                text: store.binding(
                    get: \.issuer,
                    send: EditAuthenticatorItemAction.issuerChanged
                )
            )
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

    private var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.savePressed)
        }
        .accessibilityIdentifier("SaveButton")
        .buttonStyle(.primary())
    }

    private var deleteButton: some View {
        AsyncButton(Localizations.delete) {
            await store.perform(.deletePressed)
        }
        .accessibilityIdentifier("DeleteButton")
        .buttonStyle(.tertiary(isDestructive: true))
    }
}

#if DEBUG
#Preview("Advanced Closed") {
    EditAuthenticatorItemView(
        store: Store(
            processor: StateProcessor(
                state: AuthenticatorItemState(
                    accountName: "Account",
                    algorithm: .sha1,
                    configuration: .existing(
                        authenticatorItemView: AuthenticatorItemView(
                            id: "Example",
                            name: "Example",
                            totpKey: "example"
                        )
                    ),
                    digits: 6,
                    id: "1",
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
                    )
                )
                .editState
            )
        )
    )
}

#Preview("Advanced Open") {
    EditAuthenticatorItemView(
        store: Store(
            processor: StateProcessor(
                state: AuthenticatorItemState(
                    accountName: "Account",
                    algorithm: .sha1,
                    configuration: .existing(
                        authenticatorItemView: AuthenticatorItemView(
                            id: "Example",
                            name: "Example",
                            totpKey: "example"
                        )
                    ),
                    digits: 6,
                    id: "1",
                    isAdvancedExpanded: true,
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
                    )
                )
                .editState
            )
        )
    )
}
#endif
