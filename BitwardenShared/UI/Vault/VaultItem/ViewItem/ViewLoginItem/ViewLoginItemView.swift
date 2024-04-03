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

        if !store.state.password.isEmpty {
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

        if let fido2Credential = store.state.fido2Credentials.first {
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

        if !store.state.isTOTPAvailable {
            BitwardenField(title: Localizations.verificationCodeTotp, titleAccessibilityIdentifier: "ItemName") {
                Text(Localizations.premiumSubscriptionRequired)
                    .styleGuide(.footnote)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .accessibilityIdentifier("ItemValue")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        } else if let totpModel = store.state.totpCode {
            BitwardenField(
                title: Localizations.verificationCodeTotp,
                titleAccessibilityIdentifier: "ItemName",
                content: {
                    Text(totpModel.displayCode)
                        .styleGuide(.bodyMonospaced)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .accessibilityIdentifier("ItemValue")
                },
                accessoryContent: {
                    TOTPCountdownTimerView(
                        timeProvider: timeProvider,
                        totpCode: totpModel,
                        onExpiration: {
                            Task {
                                await store.perform(.totpCodeExpired)
                            }
                        }
                    )
                    Button {
                        store.send(.copyPressed(value: totpModel.code, field: .totp))
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
}
