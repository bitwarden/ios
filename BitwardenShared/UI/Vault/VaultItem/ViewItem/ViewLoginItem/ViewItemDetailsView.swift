import SwiftUI

// MARK: - ViewItemDetailsView

/// A view for displaying the contents of a Vault item details.
struct ViewItemDetailsView: View {
    // MARK: Private Properties

    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewVaultItemState, ViewItemAction, ViewItemEffect>

    var body: some View {
        itemInformationSection

        uriSection

        if !store.state.notes.isEmpty {
            notesSection
        }

        if !store.state.customFields.isEmpty {
            customFieldsSection
        }

        updatedDate
    }

    /// The item information section.
    var itemInformationSection: some View {
        SectionView(Localizations.itemInformation, contentSpacing: 12) {
            BitwardenTextValueField(title: Localizations.name, value: store.state.name)

            // check for login type and add user name and password views.
            if store.state.type == .login, let loginState = store.state.loginState {
                if !loginState.username.isEmpty {
                    let username = loginState.username
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

                if !loginState.password.isEmpty {
                    let password = loginState.password
                    BitwardenField(title: Localizations.password) {
                        PasswordText(password: password, isPasswordVisible: loginState.isPasswordVisible)
                            .styleGuide(.body)
                            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    } accessoryContent: {
                        PasswordVisibilityButton(isPasswordVisible: loginState.isPasswordVisible) {
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
            }
        }
    }

    /// The URIs section (login only).
    @ViewBuilder var uriSection: some View {
        if store.state.type == .login, let loginState = store.state.loginState, !loginState.uris.isEmpty {
            SectionView(Localizations.urIs) {
                ForEach(loginState.uris, id: \.self) { uri in
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
    }

    /// The notes section.
    var notesSection: some View {
        SectionView(Localizations.notes) {
            BitwardenTextValueField(value: store.state.notes)
        }
    }

    /// The custom fields section.
    var customFieldsSection: some View {
        SectionView(Localizations.customFields) {
            ForEach(store.state.customFields, id: \.self) { customField in
                BitwardenField(title: customField.name) {
                    switch customField.type {
                    case .boolean:
                        let image = customField.booleanValue
                            ? Asset.Images.checkSquare.swiftUIImage
                            : Asset.Images.square.swiftUIImage
                        image
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    case .hidden:
                        if let value = customField.value {
                            PasswordText(
                                password: value,
                                isPasswordVisible: customField.isPasswordVisible
                            )
                        }
                    case .text:
                        if let value = customField.value {
                            Text(value)
                        }
                    case .linked:
                        if let linkedIdType = customField.linkedIdType {
                            HStack(spacing: 8) {
                                Asset.Images.link.swiftUIImage
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                Text(linkedIdType.localizedName)
                            }
                        }
                    }
                } accessoryContent: {
                    if let value = customField.value {
                        switch customField.type {
                        case .hidden:
                            PasswordVisibilityButton(isPasswordVisible: customField.isPasswordVisible) {
                                store.send(.customFieldVisibilityPressed(customField))
                            }
                            Button {
                                store.send(.copyPressed(value: value))
                            } label: {
                                Asset.Images.copy.swiftUIImage
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                        case .text:
                            Button {
                                store.send(.copyPressed(value: value))
                            } label: {
                                Asset.Images.copy.swiftUIImage
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                        case .boolean, .linked:
                            EmptyView()
                        }
                    }
                }
            }
        }
    }

    /// The updated date footer..
    @ViewBuilder var updatedDate: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormattedDateTimeView(label: Localizations.dateUpdated, date: store.state.updatedDate)

            if store.state.type == .login, let passwordUpdatedDate = store.state.loginState?.passwordUpdatedDate {
                FormattedDateTimeView(label: Localizations.datePasswordUpdated, date: passwordUpdatedDate)
            }
            // TODO: BIT-1186 Display the password history button here
        }
        .font(.subheadline)
        .multilineTextAlignment(.leading)
        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
    }
}
