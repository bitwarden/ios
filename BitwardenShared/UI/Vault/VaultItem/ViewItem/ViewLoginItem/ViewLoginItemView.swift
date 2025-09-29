import BitwardenKit
import BitwardenResources
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
        if !store.state.isEmpty {
            SectionView(Localizations.loginCredentials, contentSpacing: 8) {
                ContentBlock {
                    if !store.state.username.isEmpty {
                        usernameRow
                    }

                    if !store.state.password.isEmpty {
                        passwordRow
                    }

                    if let fido2Credential = store.state.fido2Credentials.first {
                        passkeyRow(fido2Credential)
                    }
                }

                if let totpModel = store.state.totpCode {
                    if store.state.isTOTPAvailable {
                        totpRow(totpModel)
                    } else {
                        premiumSubscriptionRequired
                    }
                }
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
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .accessibilityIdentifier("LoginPasswordEntry")
        } accessoryContent: {
            if store.state.canViewPassword {
                PasswordVisibilityButton(isPasswordVisible: store.state.isPasswordVisible) {
                    store.send(.passwordVisibilityPressed)
                }

                Button {
                    store.send(.copyPressed(value: password, field: .password))
                } label: {
                    Asset.Images.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("LoginCopyPasswordButton")
            }
        } footerContent: {
            if store.state.canViewPassword {
                AsyncButton(Localizations.checkPasswordForDataBreaches) {
                    await store.perform(.checkPasswordPressed)
                }
                .buttonStyle(.bitwardenBorderless)
                .padding(.vertical, 14)
                .accessibilityLabel(Localizations.checkPassword)
                .accessibilityIdentifier("CheckPasswordButton")
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// Row signifying that premium subscription is required for TOTP.
    ///
    @ViewBuilder private var premiumSubscriptionRequired: some View {
        BitwardenField(
            title: Localizations.authenticatorKey,
            titleAccessibilityIdentifier: "ItemName"
        ) {
            Text(Localizations.premiumSubscriptionRequired)
                .styleGuide(.footnote)
                .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
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
                Asset.Images.copy24.swiftUIImage
                    .imageStyle(.accessoryIcon24)
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
            value: Localizations.createdX(fido2Credential.creationDate.dateTimeDisplay)
        )
        .accessibilityIdentifier("LoginPasskeyEntry")
        .accessibilityElement(children: .contain)
    }

    /// The TOTP row.
    ///
    /// - Parameter model: The TOTP code model.
    /// - Returns: The TOTP code row.
    ///
    private func totpRow(_ model: TOTPCodeModel) -> some View {
        BitwardenField(
            title: Localizations.authenticatorKey,
            titleAccessibilityIdentifier: "ItemName",
            content: {
                Text(model.displayCode)
                    .styleGuide(.bodyMonospaced)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("LoginTotpEntry")
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
                    Asset.Images.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("CopyTotpValueButton")
            }
        )
        .accessibilityElement(children: .contain)
    }
}
