import SwiftUI

// MARK: - ViewItemDetailsView

/// A view for displaying the contents of a Vault item details.
struct ViewItemDetailsView: View {
    // MARK: Private Properties

    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewVaultItemState, ViewItemAction, ViewItemEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

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

            // check for type
            switch store.state.type {
            case .card:
                ViewCardItemView(
                    store: store.child(
                        state: { _ in store.state.cardItemViewState },
                        mapAction: { $0 },
                        mapEffect: nil
                    )
                )
            case .identity:
                ViewIdentityItemView(
                    store: store.child(
                        state: { _ in store.state.identityState },
                        mapAction: { $0 },
                        mapEffect: nil
                    )
                )
            case .login:
                ViewLoginItemView(
                    store: store.child(
                        state: { _ in store.state.loginState },
                        mapAction: { $0 },
                        mapEffect: { $0 }
                    ),
                    timeProvider: timeProvider
                )
            case .secureNote:
                EmptyView()
            }
        }
    }

    /// The URIs section (login only).
    @ViewBuilder var uriSection: some View {
        if store.state.type == .login, !store.state.loginState.uris.isEmpty {
            SectionView(Localizations.urIs) {
                ForEach(store.state.loginState.uris, id: \.self) { uri in
                    BitwardenTextValueField(title: Localizations.uri, value: uri.uri) {
                        Button {
                            guard let url = URL(string: uri.uri) else {
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
                            store.send(.copyPressed(value: uri.uri))
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

    /// The updated date footer.
    @ViewBuilder var updatedDate: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormattedDateTimeView(label: Localizations.dateUpdated, date: store.state.updatedDate)

            if store.state.type == .login {
                if let passwordUpdatedDate = store.state.loginState.passwordUpdatedDate {
                    FormattedDateTimeView(label: Localizations.datePasswordUpdated, date: passwordUpdatedDate)
                }

                if let passwordHistoryCount = store.state.loginState.passwordHistoryCount, passwordHistoryCount > 0 {
                    HStack(spacing: 4) {
                        Text(Localizations.passwordHistory + ":")

                        Button {
                            store.send(.passwordHistoryPressed)
                        } label: {
                            Text("\(passwordHistoryCount)")
                                .underline(color: Asset.Colors.primaryBitwarden.swiftUIColor)
                        }
                        .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)
                        .id("passwordHistoryButton")
                    }
                    .accessibilityLabel(Localizations.passwordHistory + ": \(passwordHistoryCount)")
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .styleGuide(.subheadline)
        .multilineTextAlignment(.leading)
        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
    }
}
