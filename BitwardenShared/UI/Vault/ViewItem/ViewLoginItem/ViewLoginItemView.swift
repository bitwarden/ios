import SwiftUI

// MARK: - ViewLoginItemView

/// A view for displaying the contents of a login item.
struct ViewLoginItemView: View {
    // MARK: Private Properties

    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewLoginItemState, ViewItemAction, Void>

    var body: some View {
        section(title: Localizations.itemInformation) {
            BitwardenField(title: Localizations.name) {
                Text(store.state.name)
            }

            if let username = store.state.username {
                BitwardenField(title: Localizations.username) {
                    Text(username)
                        .font(.styleGuide(.body))
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                } accessoryContent: {
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

            if let password = store.state.password {
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

            BitwardenField(title: Localizations.verificationCodeTotp) {
                Text(Localizations.premiumSubscriptionRequired)
                    .font(.styleGuide(.footnote))
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
            }
        }

        if !store.state.uris.isEmpty {
            section(title: Localizations.urIs) {
                ForEach(store.state.uris, id: \.self) { uri in
                    if let uri = uri.uri {
                        BitwardenField(title: Localizations.uri) {
                            Text(uri)
                                .lineLimit(1)
                        } accessoryContent: {
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

        if let notes = store.state.notes {
            section(title: Localizations.notes) {
                BitwardenField {
                    Text(notes)
                        .font(.styleGuide(.body))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                }
            }
        }

        if !store.state.customFields.isEmpty {
            section(title: Localizations.customFields) {
                ForEach(store.state.customFields, id: \.self) { customField in
                    BitwardenField(title: customField.name) {
                        if let value = customField.value {
                            Text(value)
                        }
                    }
                }
            }
        }

        let formattedDate = store.state.updatedDate.formatted(date: .numeric, time: .shortened)
        Text("\(Localizations.dateUpdated): \(formattedDate)")
            .font(.subheadline)
            .multilineTextAlignment(.leading)
            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
    }

    // MARK: Private Methods

    /// Creates a section with a title hosted in a title view.
    ///
    /// - Parameters:
    ///   - title: The title of this section.
    ///   - content: The content to place below the title view in this section.
    ///
    @ViewBuilder
    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title.uppercased())
                .font(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
        }
    }
}
