import SwiftUI

// MARK: - ViewLoginItemView

/// A view for displaying the contents of a login item.
struct ViewLoginItemView: View {
    // MARK: Private Properties

    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<LoginItemState, ViewItemAction, ViewItemEffect>

    var body: some View {
        viewItemProperties
    }

    var uriSection: some View {
        SectionView(Localizations.urIs) {
            ForEach(store.state.uris, id: \.self) { uri in
                if let uri = uri.uri {
                    BitwardenTextValueField(title: Localizations.uri, value: uri) {
                        Button {
                            guard let url = URL(string: uri) else {
                                return
                            }
                            openURL(url)
                        } label: {
                            Asset.Images.externalLink.swiftUIImage
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        .accessibilityLabel(Localizations.launch)

                        Button {
                            store.send(.copyPressed(value: uri))
                        } label: {
                            Asset.Images.copy.swiftUIImage
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        .accessibilityLabel(Localizations.copy)
                    }
                }
            }
        }
    }

    /// The view item properties.
    @ViewBuilder var viewItemProperties: some View {
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

        // TODO: BIT-1120 Add full support for TOTP display
        BitwardenField(title: Localizations.verificationCodeTotp) {
            Text(Localizations.premiumSubscriptionRequired)
                .styleGuide(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
        }

        if !store.state.uris.isEmpty {
            uriSection
        }
    }

    // MARK: Methods

    @ViewBuilder
    func passwordUpdatedDate() -> some View {
        if let passwordUpdatedDate = store.state.passwordUpdatedDate {
            FormattedDateTimeView(label: Localizations.datePasswordUpdated, date: passwordUpdatedDate)
        }
    }
}
