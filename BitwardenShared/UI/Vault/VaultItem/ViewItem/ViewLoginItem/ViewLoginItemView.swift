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

        if !store.state.isTOTPAvailable {
            premiumSubscriptionRequired
        } else if let totpModel = store.state.totpCode {
            totpRow(totpModel)
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
                .accessibilityIdentifier("ItemValue")
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
                .accessibilityIdentifier("CopyValueButton")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ItemRow")
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
        .accessibilityIdentifier("ItemRow")
    }

    /// The username field.
    ///
    @ViewBuilder private var usernameRow: some View {
        let username = store.state.username
        BitwardenTextValueField(title: Localizations.username, value: username) {
            Button {
                store.send(.copyPressed(value: username, field: .username))
            } label: {
                Asset.Images.copy.swiftUIImage
                    .imageStyle(.accessoryIcon)
            }
            .accessibilityLabel(Localizations.copy)
            .accessibilityIdentifier("CopyValueButton")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ItemRow")
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
        .accessibilityIdentifier("ItemRow")
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
                if store.state.canViewTotp {
                    Text(model.displayCode)
                        .styleGuide(.bodyMonospaced)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .accessibilityIdentifier("ItemValue")
                } else {
                    PasswordText(password: model.displayCode, isPasswordVisible: false)
                        .accessibilityIdentifier("ItemValue")
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
                .accessibilityIdentifier("CopyValueButton")
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ItemRow")
    }
}
