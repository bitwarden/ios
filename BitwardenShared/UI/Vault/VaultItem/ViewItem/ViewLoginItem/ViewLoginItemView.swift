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
        viewItemProperties
    }

    var itemInformationSection: some View {
        SectionView(Localizations.itemInformation, contentSpacing: 12) {
            BitwardenTextValueField(title: Localizations.name, value: store.state.name)

            if !store.state.loginState.username.isEmpty {
                let username = store.state.loginState.username
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

            if !store.state.loginState.password.isEmpty {
                let password = store.state.loginState.password
                BitwardenField(title: Localizations.password) {
                    PasswordText(password: password, isPasswordVisible: store.state.loginState.isPasswordVisible)
                        .styleGuide(.body)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                } accessoryContent: {
                    PasswordVisibilityButton(isPasswordVisible: store.state.loginState.isPasswordVisible) {
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

    var uriSection: some View {
        SectionView(Localizations.urIs) {
            ForEach(store.state.loginState.uris, id: \.self) { uri in
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

    var notesSection: some View {
        SectionView(Localizations.notes) {
            BitwardenTextValueField(value: store.state.notes)
        }
    }

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

    var updatedDate: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormattedDateTimeView(label: Localizations.dateUpdated, date: store.state.updatedDate)

            passwordUpdatedDate()

            // TODO: BIT-1186 Display the password history button here
        }
        .font(.subheadline)
        .multilineTextAlignment(.leading)
        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
    }

    @ViewBuilder 
    func passwordUpdatedDate() -> some View {
        if let passwordUpdatedDate = store.state.loginState.passwordUpdatedDate {
            FormattedDateTimeView(label: Localizations.datePasswordUpdated, date: passwordUpdatedDate)
        }
    }

    /// The view item properties.
    @ViewBuilder var viewItemProperties: some View {
        itemInformationSection

        if !store.state.loginState.uris.isEmpty {
            uriSection
        }

        if !store.state.notes.isEmpty {
            notesSection
        }

        if !store.state.customFields.isEmpty {
            customFieldsSection
        }

        updatedDate

    }
}
