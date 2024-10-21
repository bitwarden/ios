import BitwardenSdk
import SwiftUI

// MARK: - ViewLoginItemView

/// A view for displaying the contents of a login item.
struct ViewLoginItemView: View {
    // MARK: Private Properties

    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewLoginItemState, ViewItemAction, ViewItemEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        if !store.state.username.isEmpty {
            usernameRow
        }

        if !store.state.password.isEmpty {
            passwordRow
        }

        if let fido2Credential = store.state.fido2Credentials.first {
            passkeyRow(fido2Credential)
        }

        if let totpModel = store.state.totpCode {
            if store.state.isTOTPAvailable {
                totpRow(totpModel)
            } else {
                premiumSubscriptionRequired
            }
        }
    }

    // MARK: Private views

    /// The password row.
    ///
    @ViewBuilder private var passwordRow: some View {
        let password = store.state.password
        BitwardenField(title: Localizations.password, titleAccessibilityIdentifier: "ItemName") {
            PasswordText(password: password, isPasswordVisible: store.state.isPasswordVisible)
                .styleGuide(.body)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .accessibilityIdentifier("LoginPasswordEntry")
        } accessoryContent: {
            if store.state.canViewPassword {
                PasswordVisibilityButton(isPasswordVisible: store.state.isPasswordVisible) {
                    store.send(.passwordVisibilityPressed)
                }

                AsyncButton {
                    await store.perform(.checkPasswordPressed)
                } label: {
                    Asset.Images.roundCheck.swiftUIImage
                        .imageStyle(.accessoryIcon)
                }
                .accessibilityLabel(Localizations.checkPassword)
                .accessibilityIdentifier("CheckPasswordButton")

                Button {
                    store.send(.copyPressed(value: password, field: .password))
                } label: {
                    Asset.Images.copy.swiftUIImage
                        .imageStyle(.accessoryIcon)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("LoginCopyPasswordButton")
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// Row signifying that premium subscription is required for TOTP.
    ///
    @ViewBuilder private var premiumSubscriptionRequired: some View {
        BitwardenField(
            title: Localizations.verificationCodeTotp,
            titleAccessibilityIdentifier: "ItemName"
        ) {
            Text(Localizations.premiumSubscriptionRequired)
                .styleGuide(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                .accessibilityIdentifier("ItemValue")
        }
        .accessibilityElement(children: .contain)
    }

    /// The username field.
    ///
    @ViewBuilder private var usernameRow: some View {
        let username = store.state.username
        BitwardenTextValueField(
            title: Localizations.username,
            value: username,
            valueAccessibilityIdentifier: "LoginUsernameEntry"
        ) {
            Button {
                store.send(.copyPressed(value: username, field: .username))
            } label: {
                Asset.Images.copy.swiftUIImage
                    .imageStyle(.accessoryIcon)
            }
            .accessibilityLabel(Localizations.copy)
            .accessibilityIdentifier("LoginCopyUsernameButton")
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Methods

    /// The passkey row.
    ///
    private func passkeyRow(_ fido2Credential: Fido2Credential) -> some View {
        BitwardenTextValueField(
            title: Localizations.passkey,
            value: Localizations.createdXY(
                fido2Credential.creationDate.formatted(date: .numeric, time: .omitted),
                fido2Credential.creationDate.formatted(date: .omitted, time: .shortened)
            )
        )
        .accessibilityElement(children: .contain)
    }

    /// The TOTP row.
    ///
    /// - Parameter model: The TOTP code model.
    /// - Returns: The TOTP code row.
    ///
    private func totpRow(_ model: TOTPCodeModel) -> some View {
        BitwardenField(
            title: Localizations.verificationCodeTotp,
            titleAccessibilityIdentifier: "ItemName",
            content: {
                if store.state.isTOTPCodeVisible {
                    Text(model.displayCode)
                        .styleGuide(.bodyMonospaced)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .accessibilityIdentifier("LoginTotpEntry")
                } else {
                    PasswordText(password: model.displayCode, isPasswordVisible: false)
                        .accessibilityIdentifier("LoginTotpEntry")
                }
            },
            accessoryContent: {
                TOTPCountdownTimerView(
                    timeProvider: timeProvider,
                    totpCode: model,
                    onExpiration: {
                        Task {
                            await store.perform(.totpCodeExpired)
                        }
                    }
                )
                Button {
                    store.send(.copyPressed(value: model.code, field: .totp))
                } label: {
                    Asset.Images.copy.swiftUIImage
                        .imageStyle(.accessoryIcon)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("CopyTotpValueButton")
            }
        )
        .accessibilityElement(children: .contain)
    }
}
