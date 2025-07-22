import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - ViewItemDetailsView

/// A view for displaying the contents of a Vault item details.
struct ViewItemDetailsView: View { // swiftlint:disable:this type_body_length
    // MARK: Private Properties

    /// Whether the second item in the collections list is focused. This is used alongside the Show more/less button.
    @AccessibilityFocusState private var isSecondCollectionFocused: Bool

    @Environment(\.openURL) private var openURL

    /// The top padding to use in the `belongingView` image.
    @ScaledMetric(relativeTo: .body)
    private var paddingTopBelongingViewImage = 4

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewVaultItemState, ViewItemAction, ViewItemEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        itemHeaderSection

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
            SectionView(Localizations.attachments, contentSpacing: 8) {
                ContentBlock {
                    ForEach(attachments) { attachment in
                        attachmentRow(attachment, hasDivider: attachment != attachments.last)
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("AttachmentsList")
        }
    }

    /// The custom fields section.
    @ViewBuilder private var customFieldsSection: some View {
        if !store.state.customFieldsState.customFields.isEmpty {
            SectionView(Localizations.customFields, contentSpacing: 8) {
                ForEach(store.state.customFieldsState.customFields, id: \.self) { customField in
                    if customField.type == .boolean {
                        HStack(spacing: 16) {
                            let image = customField.booleanValue
                                ? Asset.Images.checkSquare16.swiftUIImage
                                : Asset.Images.square16.swiftUIImage
                            image
                                .imageStyle(.accessoryIcon16(color: SharedAsset.Colors.textSecondary.swiftUIColor))

                            Text(customField.name ?? "")
                                .styleGuide(.body)
                        }
                        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
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
                                } else {
                                    Text(" ") // Placeholder so the field's title is positioned correctly.
                                }
                            case .text:
                                // An empty string is a placeholder when the value is nil so the
                                // field's title is positioned correctly.
                                Text(customField.value ?? "")
                                    .textSelection(.enabled)
                                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                                    .styleGuide(.body)
                            case .linked:
                                if let linkedIdType = customField.linkedIdType {
                                    HStack(spacing: 8) {
                                        Asset.Images.link16.swiftUIImage
                                            .imageStyle(
                                                .accessoryIcon16(color: SharedAsset.Colors.textSecondary.swiftUIColor)
                                            )
                                        Text(linkedIdType.localizedName)
                                            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                                            .styleGuide(.body)
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
                                        Asset.Images.copy24.swiftUIImage
                                            .imageStyle(.accessoryIcon24)
                                    }
                                    .accessibilityIdentifier("HiddenCustomFieldCopyValueButton")
                                case .text:
                                    Button {
                                        store.send(.copyPressed(value: value, field: .customTextField))
                                    } label: {
                                        Asset.Images.copy24.swiftUIImage
                                            .imageStyle(.accessoryIcon24)
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

    /// A section with additional details to display on the header details.
    @ViewBuilder private var itemHeaderAdditionalDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            if store.state.shouldDisplayNoFolder {
                belongingView(
                    icon: Asset.Images.folder16,
                    name: Localizations.folderNone
                )
                .padding(.leading, 8)
                .accessibilityLabel(Localizations.folderX(Localizations.folderNone))
            } else {
                itemHeaderBelongingToSection
                    .padding(.leading, 8)

                if store.state.belongsToMultipleCollections {
                    AsyncButton(store.state.multipleCollectionsDisplayButtonTitle) {
                        await store.perform(.toggleDisplayMultipleCollections)
                    }
                    .buttonStyle(.bitwardenBorderless)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
                    .accessibilityLabel(store.state.multipleCollectionsDisplayButtonTitle)
                    .accessibilityIdentifier("ToggleDisplayMultipleCollectionsButton")
                }
            }
        }
        .padding(12)
    }

    /// A section displaying where the item belongs to, i.e. organization, collections and folder.
    @ViewBuilder private var itemHeaderBelongingToSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let organizationName = store.state.organizationName {
                belongingView(
                    icon: Asset.Images.business16,
                    name: organizationName
                )
                .accessibilityLabel(Localizations.ownerX(organizationName))
                .accessibilityHint(Localizations.itemXOfY(1, store.state.totalHeaderAdditionalItems))
            }

            if !store.state.cipherCollectionsToDisplay.isEmpty {
                ForEachIndexed(store.state.cipherCollectionsToDisplay) { index, collection in
                    VStack(alignment: .leading, spacing: 0) {
                        belongingView(
                            icon: Asset.Images.collections16,
                            name: collection.name
                        )
                        .accessibilityLabel(Localizations.collectionX(collection.name))
                        .accessibilityHint(Localizations.itemXOfY(index + 2, store.state.totalHeaderAdditionalItems))
                        .if(index == 1) { view in
                            view.accessibilityFocused($isSecondCollectionFocused)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if store.state.shouldDisplayFolder, let folderName = store.state.folderName {
                belongingView(
                    icon: Asset.Images.folder16,
                    name: folderName
                )
                .accessibilityLabel(Localizations.folderX(folderName))
                .accessibilityHint(
                    Localizations.itemXOfY(
                        store.state.totalHeaderAdditionalItems,
                        store.state.totalHeaderAdditionalItems
                    )
                )
            }
        }
    }

    /// The main details header section.
    private var itemHeaderMainDetails: some View {
        HStack(spacing: 12) {
            VaultItemDecorativeImageView(
                item: store.state,
                iconBaseURL: store.state.iconBaseURL,
                showWebIcons: store.state.showWebIcons
            ) { placeholderIconAsset in
                Image(decorative: placeholderIconAsset)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(SharedAsset.Colors.illustrationOutline.swiftUIColor)
                    .accessibilityHidden(true)
                    .imageStyle(.viewIcon(size: 24))
                    .withCircularBackground(
                        color: SharedAsset.Colors.illustrationBgPrimary.swiftUIColor,
                        width: 36,
                        height: 36
                    )
            }
            .imageStyle(.viewIcon())
            .accessibilityHidden(true)
            .padding(.vertical, 5)

            Text(store.state.name)
                .styleGuide(.title2, weight: .semibold, includeLinePadding: false, includeLineSpacing: false)
                .multilineTextAlignment(.leading)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .accessibilityIdentifier(store.state.name)
                .accessibilityLabel(Localizations.itemNameX(store.state.name))
                .frame(maxWidth: .infinity, alignment: .leading)

            let image = store.state.isFavoriteOn
                ? Asset.Images.starFilled24.swiftUIImage
                : Asset.Images.star24.swiftUIImage
            image
                .foregroundStyle(SharedAsset.Colors.iconPrimary.swiftUIColor)
                .accessibilityLabel(Localizations.favorite)
                .accessibilityValue(store.state.isFavoriteOn ? Localizations.on : Localizations.off)
                .buttonStyle(.accessory)
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .frame(minHeight: 64)
        .accessibilityElement(children: .contain)
    }

    /// The item header section.
    private var itemHeaderSection: some View {
        ContentBlock(dividerLeadingPadding: 12) {
            itemHeaderMainDetails

            itemHeaderAdditionalDetails
        }
        .onChange(of: store.state.isShowingMultipleCollections) { value in
            if value {
                isSecondCollectionFocused = true
            }
        }
    }

    /// The item information section.
    @ViewBuilder private var itemInformationSection: some View {
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

    /// The notes section.
    @ViewBuilder private var notesSection: some View {
        if !store.state.notes.isEmpty {
            let notes = store.state.notes
            let notesView = BitwardenTextValueField(
                title: Localizations.notes,
                value: notes,
                useUIKitTextView: true,
                copyButtonAccessibilityIdentifier: "CopyNotesButton",
                copyButtonAction: { store.send(.copyPressed(value: notes, field: .notes))
                }
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("CipherNotesLabel")
            if store.state.type == .secureNote {
                notesView
                    // The secure note type doesn't have a top-level section header for its field, so
                    // remove the extra top padding (8 points of total padding from the last section as
                    // opposed to 16)
                    .padding(.top, -8)
            } else {
                SectionView(Localizations.additionalOptions) {
                    notesView
                }
            }
        }
    }

    /// The updated date footer.
    private var updatedDate: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localizations.created(store.state.cipher.creationDate.dateTimeDisplay))
                .styleGuide(.callout)

            Text(Localizations.lastEdited(store.state.updatedDate.dateTimeDisplay))
                .styleGuide(.callout)

            if store.state.type == .login {
                if let passwordUpdatedDate = store.state.loginState.passwordUpdatedDate {
                    Text(Localizations.passwordLastUpdated(passwordUpdatedDate.dateTimeDisplay))
                        .styleGuide(.callout)
                }

                if let passwordHistoryCount = store.state.loginState.passwordHistoryCount, passwordHistoryCount > 0 {
                    Button {
                        store.send(.passwordHistoryPressed)
                    } label: {
                        Text(Localizations.passwordHistory + ": \(passwordHistoryCount)")
                            .styleGuide(.callout, weight: .semibold)
                    }
                    .foregroundStyle(SharedAsset.Colors.textInteraction.swiftUIColor)
                    .id("passwordHistoryButton")
                }
            }
        }
        .multilineTextAlignment(.leading)
        .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
        .padding(.leading, 12)
    }

    /// The URIs section (login only).
    @ViewBuilder private var uriSection: some View {
        if store.state.type == .login, !store.state.loginState.uris.isEmpty {
            SectionView(Localizations.autofillOptions, contentSpacing: 8) {
                ContentBlock {
                    ForEach(store.state.loginState.uris, id: \.self) { uri in
                        BitwardenTextValueField(
                            title: Localizations.websiteURI,
                            value: URL(string: uri.uri)?.host ?? uri.uri,
                            valueAccessibilityIdentifier: "LoginUriEntry"
                        ) {
                            if let url = URL(string: uri.uri)?.sanitized, url.hasValidURLComponents {
                                Button {
                                    openURL(url)
                                } label: {
                                    Asset.Images.externalLink24.swiftUIImage
                                        .imageStyle(.accessoryIcon24)
                                }
                                .accessibilityLabel(Localizations.launch)
                            }

                            Button {
                                store.send(.copyPressed(value: uri.uri, field: .uri))
                            } label: {
                                Asset.Images.copy24.swiftUIImage
                                    .imageStyle(.accessoryIcon24)
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
    }

    // MARK: Private methods

    /// A row to display an existing attachment.
    ///
    /// - Parameters:
    ///   - attachment: The attachment to display.
    ///   - hasDivider: Whether the row should display a divider.
    ///
    private func attachmentRow(_ attachment: AttachmentView, hasDivider: Bool) -> some View {
        BitwardenField {
            HStack {
                Text(attachment.fileName ?? "")
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .lineLimit(1)

                Spacer()

                if let sizeName = attachment.sizeName {
                    Text(sizeName)
                        .styleGuide(.body)
                        .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .lineLimit(1)
                }

                Button {
                    store.send(.downloadAttachment(attachment))
                } label: {
                    Image(asset: Asset.Images.download24)
                        .imageStyle(.rowIcon(color: SharedAsset.Colors.iconSecondary.swiftUIColor))
                }
                .accessibilityLabel(Localizations.download)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("CipherAttachment")
    }

    /// Returns a view used to display where the item belongs to information.
    /// - Parameters:
    ///   - icon: The icon to display.
    ///   - name: The name to display.
    /// - Returns: A view with an icon and a name stating where the item belongs to.
    @ViewBuilder
    private func belongingView(icon: ImageAsset, name: String) -> some View {
        HStack(alignment: .top) {
            Image(decorative: icon)
                .resizable()
                .foregroundStyle(SharedAsset.Colors.iconPrimary.swiftUIColor)
                .scaledToFit()
                .imageStyle(.accessoryIcon16(scaleWithFont: true))
                .padding(.top, paddingTopBelongingViewImage)

            Text(name)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
        }
        .accessibilityElement(children: .combine)
    }
} // swiftlint:disable:this file_length
