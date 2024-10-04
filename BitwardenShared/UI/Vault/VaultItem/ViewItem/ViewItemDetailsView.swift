import BitwardenSdk
import SwiftUI

// MARK: - ViewItemDetailsView

/// A view for displaying the contents of a Vault item details.
struct ViewItemDetailsView: View { // swiftlint:disable:this type_body_length
    // MARK: Private Properties

    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewVaultItemState, ViewItemAction, ViewItemEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        itemInformationSection

        uriSection

        notesSection

        customFieldsSection

        attachmentsSection

        updatedDate
    }

    // MARK: Private Views

    /// The attachments section.
    @ViewBuilder private var attachmentsSection: some View {
        if let attachments = store.state.attachments, !attachments.isEmpty {
            SectionView(Localizations.attachments) {
                VStack(spacing: 0) {
                    ForEach(attachments) { attachment in
                        attachmentRow(attachment, hasDivider: attachment != attachments.last)
                    }
                }
                .cornerRadius(10)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("AttachmentsList")
        }
    }

    /// The custom fields section.
    @ViewBuilder private var customFieldsSection: some View {
        if !store.state.customFieldsState.customFields.isEmpty {
            SectionView(Localizations.customFields) {
                ForEach(store.state.customFieldsState.customFields, id: \.self) { customField in
                    if customField.type == .boolean {
                        HStack(spacing: 16) {
                            let image = customField.booleanValue
                                ? Asset.Images.checkSquare.swiftUIImage
                                : Asset.Images.square.swiftUIImage
                            image
                                .imageStyle(.accessoryIcon(color: Asset.Colors.textSecondary.swiftUIColor))

                            Text(customField.name ?? "")
                                .styleGuide(.body)
                        }
                        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        BitwardenField(title: customField.name) {
                            switch customField.type {
                            case .boolean:
                                EmptyView()
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
                                            .imageStyle(.accessoryIcon(color: Asset.Colors.textSecondary.swiftUIColor))
                                        Text(linkedIdType.localizedName)
                                    }
                                }
                            }
                        } accessoryContent: {
                            if let value = customField.value {
                                switch customField.type {
                                case .hidden:
                                    PasswordVisibilityButton(
                                        accessibilityIdentifier: "HiddenCustomFieldShowValueButton",
                                        isPasswordVisible: customField.isPasswordVisible
                                    ) {
                                        store.send(.customFieldVisibilityPressed(customField))
                                    }
                                    Button {
                                        store.send(.copyPressed(value: value, field: .customHiddenField))
                                    } label: {
                                        Asset.Images.copy.swiftUIImage
                                            .imageStyle(.accessoryIcon)
                                    }
                                    .accessibilityIdentifier("HiddenCustomFieldCopyValueButton")
                                case .text:
                                    Button {
                                        store.send(.copyPressed(value: value, field: .customTextField))
                                    } label: {
                                        Asset.Images.copy.swiftUIImage
                                            .imageStyle(.accessoryIcon)
                                    }
                                    .accessibilityIdentifier("TextCustomFieldCopyValueButton")
                                case .boolean, .linked:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// The item information section.
    private var itemInformationSection: some View {
        SectionView(Localizations.itemInformation, contentSpacing: 12) {
            BitwardenTextValueField(title: Localizations.name, value: store.state.name)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("ItemRow")

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
            case .sshKey:
                ViewSSHKeyItemView(
                    showCopyButtons: true,
                    store: store.child(
                        state: { _ in store.state.sshKeyState },
                        mapAction: { .sshKeyItemAction($0) },
                        mapEffect: nil
                    )
                )
            }
        }
    }

    /// The notes section.
    @ViewBuilder private var notesSection: some View {
        if !store.state.notes.isEmpty {
            SectionView(Localizations.notes) {
                BitwardenTextValueField(value: store.state.notes, textSelectionEnabled: true)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("CipherNotesLabel")
        }
    }

    /// The updated date footer.
    private var updatedDate: some View {
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
                                .underline(color: Asset.Colors.textInteraction.swiftUIColor)
                        }
                        .foregroundStyle(Asset.Colors.textInteraction.swiftUIColor)
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

    /// The URIs section (login only).
    @ViewBuilder private var uriSection: some View {
        if store.state.type == .login, !store.state.loginState.uris.isEmpty {
            SectionView(Localizations.urIs) {
                ForEach(store.state.loginState.uris, id: \.self) { uri in
                    BitwardenTextValueField(
                        title: Localizations.uri,
                        value: URL(string: uri.uri)?.host ?? uri.uri,
                        valueAccessibilityIdentifier: "LoginUriEntry"
                    ) {
                        if let url = URL(string: uri.uri)?.sanitized, url.hasValidURLComponents {
                            Button {
                                openURL(url)
                            } label: {
                                Asset.Images.externalLink.swiftUIImage
                                    .imageStyle(.accessoryIcon)
                            }
                            .accessibilityLabel(Localizations.launch)
                        }

                        Button {
                            store.send(.copyPressed(value: uri.uri, field: .uri))
                        } label: {
                            Asset.Images.copy.swiftUIImage
                                .imageStyle(.accessoryIcon)
                        }
                        .accessibilityLabel(Localizations.copy)
                        .accessibilityIdentifier("CopyValueButton")
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("UriRow")
                }
            }
        }
    }

    /// A row to display an existing attachment.
    ///
    /// - Parameters:
    ///   - attachment: The attachment to display.
    ///   - hasDivider: Whether the row should display a divider.
    ///
    private func attachmentRow(_ attachment: AttachmentView, hasDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(attachment.fileName ?? "")
                    .styleGuide(.body)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    .lineLimit(1)

                Spacer()

                if let sizeName = attachment.sizeName {
                    Text(sizeName)
                        .styleGuide(.body)
                        .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                        .lineLimit(1)
                }

                Button {
                    store.send(.downloadAttachment(attachment))
                } label: {
                    Image(asset: Asset.Images.download)
                        .imageStyle(.rowIcon(color: Asset.Colors.iconSecondary.swiftUIColor))
                }
                .accessibilityLabel(Localizations.download)
            }
            .padding(16)

            if hasDivider {
                Divider()
                    .padding(.leading, 16)
            }
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("CipherAttachment")
    }
}
