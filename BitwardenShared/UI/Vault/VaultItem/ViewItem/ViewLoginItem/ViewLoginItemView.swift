import SwiftUI

// MARK: - ViewLoginItemView

/// A view for displaying the contents of a login item.
struct ViewLoginItemView: View {
    // MARK: Private Properties

    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewLoginItemState, ViewItemAction, ViewItemEffect>

    var body: some View {
        if !store.state.username.isEmpty {
            let username = store.state.username
            BitwardenTextValueField(title: Localizations.username, value: username) {
                Button {
                    store.send(.copyPressed(value: username))
                } label: {
                    Asset.Images.copy.swiftUIImage
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .accessibilityLabel(Localizations.copy)
            }
        }

        if !store.state.password.isEmpty {
            let password = store.state.password
            BitwardenField(title: Localizations.password) {
                PasswordText(password: password, isPasswordVisible: store.state.isPasswordVisible)
                    .styleGuide(.body)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
            } accessoryContent: {
                PasswordVisibilityButton(isPasswordVisible: store.state.isPasswordVisible) {
                    store.send(.passwordVisibilityPressed)
                }

                Button {
                    store.send(.checkPasswordPressed)
                } label: {
                    Asset.Images.roundCheck.swiftUIImage
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .accessibilityLabel(Localizations.checkPassword)

                Button {
                    store.send(.copyPressed(value: password))
                } label: {
                    Asset.Images.copy.swiftUIImage
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .accessibilityLabel(Localizations.copy)
            }
        }

        if !store.state.isTOTPAvailable {
            BitwardenField(
                title: Localizations.verificationCodeTotp
            ) {
                Text(Localizations.premiumSubscriptionRequired)
                    .styleGuide(.footnote)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
            }
        } else if store.state.totpKey != nil {
            // TODO: BIT-760 - Implement OTP Logic & Calculation
            BitwardenField(
                title: Localizations.verificationCodeTotp,
                content: {
                    Text("123 456")
                        .styleGuide(.bodyMonospaced)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                },
                accessoryContent: {
                    Button {
                        // TODO: BIT-760 - Implement OTP Logic & Calculation
                    } label: {
                        Asset.Images.copy.swiftUIImage
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    .accessibilityLabel(Localizations.copy)
                }
            )
        }
    }
}
