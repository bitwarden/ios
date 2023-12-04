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

    /// The view item properties.
    @ViewBuilder var viewItemProperties: some View {
        VaultItemSectionView(contentSpacing: 12, titleSpacing: 15, title: Localizations.itemInformation) {
            BitwardenTextValueField(title: Localizations.name, value: store.state.properties.name)

            if !store.state.properties.username.isEmpty {
                let username = store.state.properties.username
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

            if !store.state.properties.password.isEmpty {
                let password = store.state.properties.password
                BitwardenField(title: Localizations.password) {
                    PasswordText(password: password, isPasswordVisible: store.state.isPasswordVisible)
                        .font(.styleGuide(.body))
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
                    .font(.styleGuide(.footnote))
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
            }
        }

        if !store.state.properties.uris.isEmpty {
            VaultItemSectionView(contentSpacing: 12, titleSpacing: 15, title: Localizations.urIs) {
                ForEach(store.state.properties.uris, id: \.self) { uri in
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

        if !store.state.properties.notes.isEmpty {
            let notes = store.state.properties.notes
            VaultItemSectionView(contentSpacing: 12, titleSpacing: 15, title: Localizations.notes) {
                BitwardenTextValueField(value: notes)
            }
        }

        if !store.state.properties.customFields.isEmpty {
            VaultItemSectionView(contentSpacing: 12, titleSpacing: 15, title: Localizations.customFields) {
                ForEach(store.state.properties.customFields, id: \.self) { customField in
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

        VStack(alignment: .leading, spacing: 0) {
            let formattedUpdatedDate = store.state.properties.updatedDate.formatted(date: .numeric, time: .shortened)
            Text("\(Localizations.dateUpdated): \(formattedUpdatedDate)")

            if let passwordUpdatedDate = store.state.properties.passwordUpdatedDate {
                let formattedPasswordUpdatedDate = passwordUpdatedDate.formatted(
                    date: .numeric,
                    time: .shortened
                )
                Text("\(Localizations.datePasswordUpdated): \(formattedPasswordUpdatedDate)")
            }

            // TODO: BIT-1186 Display the password history button here
        }
        .font(.subheadline)
        .multilineTextAlignment(.leading)
        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
    }
}
