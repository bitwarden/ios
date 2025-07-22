import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - AddEditItemView

/// A view that allows the user to add or edit a new item for a vault.
///
struct AddEditItemView: View {
    // MARK: Private Properties

    /// An object used to open urls in this view.
    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddEditItemState, AddEditItemAction, AddEditItemEffect>

    /// Whether to show that a policy is in effect.
    var isPolicyEnabled: Bool {
        store.state.isPersonalOwnershipDisabled && store.state.configuration == .add
    }

    // MARK: View

    var body: some View {
        Group {
            switch store.state.configuration {
            case .add:
                addView
            case .existing:
                existing
            }
        }
        .navigationTitle(store.state.navigationTitle)
        .task { await store.perform(.appeared) }
        .task { await store.perform(.fetchCipherOptions) }
        .task { await store.perform(.streamFolders) }
        .toast(store.binding(
            get: \.toast,
            send: AddEditItemAction.toastShown
        ))
    }

    private var addView: some View {
        content
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismissPressed)
                }

                saveToolbarItem {
                    await store.perform(.savePressed)
                }
            }
    }

    private var content: some View {
        GuidedTourScrollView(
            store: store.child(
                state: \.guidedTourViewState,
                mapAction: AddEditItemAction.guidedTourViewAction,
                mapEffect: nil
            )
        ) {
            VStack(spacing: 16) {
                if isPolicyEnabled {
                    InfoContainer(Localizations.personalOwnershipPolicyInEffect)
                        .accessibilityIdentifier("PersonalOwnershipPolicyLabel")
                }

                if store.state.shouldShowLearnNewLoginActionCard {
                    ActionCard(
                        title: Localizations.learnAboutNewLogins,
                        message: Localizations.weWillWalkYouThroughTheKeyFeaturesToAddANewLogin,
                        actionButtonState: ActionCard.ButtonState(title: Localizations.getStarted) {
                            await store.perform(.showLearnNewLoginGuidedTour)
                        },
                        dismissButtonState: ActionCard.ButtonState(title: Localizations.dismiss) {
                            await store.perform(.dismissNewLoginActionCard)
                        }
                    )
                }

                itemDetailsSection
                itemTypeSection
                    .disabled(store.state.isReadOnly)
                additionalOptions
                    .disabled(store.state.isReadOnly)
            }
            .padding(12)
        }
        .animation(.default, value: store.state.collectionsForOwner)
        .backport.dismissKeyboardImmediately()
        .background(
            SharedAsset.Colors.backgroundPrimary.swiftUIColor
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .backport.scrollContentMargins(Edge.Set.bottom, 30.0)
    }

    private var existing: some View {
        content
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismissPressed)
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    saveToolbarButton {
                        await store.perform(.savePressed)
                    }

                    VaultItemManagementMenuView(
                        isCloneEnabled: false,
                        isCollectionsEnabled: store.state.canAssignToCollection,
                        isDeleteEnabled: store.state.canBeDeleted,
                        isMoveToOrganizationEnabled: store.state.cipher.organizationId == nil,
                        store: store.child(
                            state: { _ in },
                            mapAction: { .morePressed($0) },
                            mapEffect: { _ in .deletePressed }
                        )
                    )
                }
            }
    }

    /// The item details section containing the name, folder, and owner fields.
    private var itemDetailsSection: some View {
        SectionView(Localizations.itemDetails, contentSpacing: 8) {
            BitwardenTextField(
                title: Localizations.itemNameRequired,
                text: store.binding(
                    get: \.name,
                    send: AddEditItemAction.nameChanged
                ),
                accessibilityIdentifier: "ItemNameEntry",
                isTextFieldDisabled: store.state.isReadOnly
            ) {
                Button {
                    store.send(.favoriteChanged(!store.state.isFavoriteOn))
                } label: {
                    store.state.isFavoriteOn
                        ? Asset.Images.starFilled24.swiftUIImage
                        : Asset.Images.star24.swiftUIImage
                }
                .buttonStyle(.accessory)
                .accessibilityIdentifier("ItemFavoriteButton")
                .accessibilityLabel(Localizations.favorite)
                .accessibilityValue(store.state.isFavoriteOn ? Localizations.on : Localizations.off)
            }
            .contentBlock()

            ContentBlock {
                BitwardenMenuField(
                    title: Localizations.folder,
                    options: store.state.folders,
                    selection: store.binding(
                        get: \.folder,
                        send: AddEditItemAction.folderChanged
                    ),
                    additionalMenu: {
                        Button(Localizations.newFolder) {
                            store.send(.addFolder)
                        }
                    }
                )
                .accessibilityIdentifier("FolderPicker")

                if store.state.configuration.isAdding, store.state.hasOrganizations, let owner = store.state.owner {
                    ContentBlock(dividerLeadingPadding: 16) {
                        BitwardenMenuField(
                            title: Localizations.owner,
                            accessibilityIdentifier: "ItemOwnershipPicker",
                            options: store.state.ownershipOptions,
                            selection: store.binding(
                                get: { _ in owner },
                                send: AddEditItemAction.ownerChanged
                            )
                        )

                        ForEach(store.state.collectionsForOwner, id: \.id) { collection in
                            if let collectionId = collection.id {
                                BitwardenToggle(
                                    collection.name,
                                    isOn: store.binding(
                                        get: { _ in store.state.collectionIds.contains(collectionId) },
                                        send: { .collectionToggleChanged($0, collectionId: collectionId) }
                                    )
                                )
                                .accessibilityIdentifier("CollectionItemSwitch")
                            }
                        }
                    }
                }
            }
        }
    }
}

private extension AddEditItemView {
    /// The expandable additional options section.
    @ViewBuilder var additionalOptions: some View {
        ExpandableContent(
            title: Localizations.additionalOptions,
            isExpanded: store.binding(
                get: \.isAdditionalOptionsExpanded,
                send: AddEditItemAction.toggleAdditionalOptionsExpanded
            )
        ) {
            if store.state.type != .secureNote {
                notesField
            }

            if store.state.showMasterPasswordReprompt {
                BitwardenToggle(isOn: store.binding(
                    get: \.isMasterPasswordRePromptOn,
                    send: AddEditItemAction.masterPasswordRePromptChanged
                )) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(Localizations.passwordPrompt)

                        Button {
                            openURL(ExternalLinksConstants.protectIndividualItems)
                        } label: {
                            Asset.Images.questionCircle16.swiftUIImage
                        }
                        .accessibilityLabel(Localizations.masterPasswordRePromptHelp)
                        .buttonStyle(.fieldLabelIcon)
                    }
                }
                .toggleStyle(.bitwarden)
                .accessibilityIdentifier("MasterPasswordRepromptToggle")
                .accessibilityLabel(Localizations.passwordPrompt)
                .contentBlock()
            }

            customSection
        }
    }

    /// The section containing custom fields.
    private var customSection: some View {
        AddEditCustomFieldsView(
            store: store.child(
                state: { $0.customFieldsState },
                mapAction: { .customField($0) },
                mapEffect: nil
            )
        )
        .animation(.easeInOut(duration: 0.2), value: store.state.customFieldsState)
    }

    /// The notes fields.
    private var notesField: some View {
        BitwardenTextView(
            title: Localizations.notes,
            text: store.binding(
                get: \.notes,
                send: AddEditItemAction.notesChanged
            ),
            isEditable: !store.state.isReadOnly
        )
        .disabled(store.state.isReadOnly)
    }
}

private extension AddEditItemView {
    /// Specific fields for a card item.
    @ViewBuilder private var cardItems: some View {
        AddEditCardItemView(
            store: store.child(
                state: { addEditState in
                    addEditState.cardItemState
                },
                mapAction: { action in
                    .cardFieldChanged(action)
                },
                mapEffect: { $0 }
            )
        )
    }

    /// Specific fields for an identity item.
    @ViewBuilder private var identityItems: some View {
        AddEditIdentityItemView(
            store: store.child(
                state: { addEditState in
                    addEditState.identityState
                },
                mapAction: { action in
                    .identityFieldChanged(action)
                },
                mapEffect: { $0 }
            )
        )
    }

    /// The specific fields for the type of item being created or updated.
    @ViewBuilder private var itemTypeSection: some View {
        switch store.state.type {
        case .card:
            cardItems
        case .login:
            loginItems
        case .secureNote:
            notesField
                // The secure note type doesn't have a top-level section header for its field, so
                // remove the extra top padding (8 points of total padding from the last field as
                // opposed to 16)
                .padding(.top, -8)
        case .identity:
            identityItems
        case .sshKey:
            sshKeyItems
        }
    }

    /// Specific fields for a login item.
    @ViewBuilder private var loginItems: some View {
        AddEditLoginItemView(
            store: store.child(
                state: { addEditState in
                    addEditState.loginState
                },
                mapAction: { $0 },
                mapEffect: { $0 }
            ),
            didRenderFrame: { step, frame in
                let enlargedFrame = frame.enlarged(by: 8)
                store.send(
                    .guidedTourViewAction(.didRenderViewToSpotlight(
                        frame: enlargedFrame,
                        step: step
                    ))
                )
            }
        )
    }

    /// Specific fields for a SSK key item.
    @ViewBuilder private var sshKeyItems: some View {
        ViewSSHKeyItemView(
            showCopyButtons: false,
            store: store.child(
                state: { _ in store.state.sshKeyState },
                mapAction: { .sshKeyItemAction($0) },
                mapEffect: nil
            )
        )
    }
}

#if DEBUG
struct AddEditItemView_Previews: PreviewProvider {
    static var cipherState: CipherItemState {
        var state = CipherItemState(
            existing: .fixture(
                favorite: true,
                login: .fixture(
                    fido2Credentials: [
                        .fixture(
                            creationDate: Date(timeIntervalSince1970: 1_710_494_110)
                        ),
                    ],
                    password: "changerdanger",
                    uris: [
                        .fixture(uri: "yahoo.com"),
                        .fixture(uri: "account.yahoo.com"),
                    ],
                    username: "EddyEddity"
                ),
                name: "Edit Em",
                type: .login
            ),
            hasPremium: true
        )!
        state.ownershipOptions = [.personal(email: "user@bitwarden.com")]
        return state
    }

    static var previews: some View {
        NavigationView {
            AddEditItemView(
                store: Store(
                    processor: StateProcessor(
                        state: CipherItemState(
                            hasPremium: true
                        ).addEditState
                    )
                )
            )
        }
        .previewDisplayName("Empty Add")

        NavigationView {
            AddEditItemView(
                store: Store(
                    processor: StateProcessor(
                        state: {
                            var state = cipherState
                            state.notes = "This is a nice note"
                            return state
                        }()
                    )
                )
            )
        }
        .previewDisplayName("Edit Notes")

        NavigationView {
            AddEditItemView(
                store: Store(
                    processor: StateProcessor(
                        state: CipherItemState(
                            addItem: .card,
                            hasPremium: true
                        )
                        .addEditState
                    )
                )
            )
        }
        .previewDisplayName("Add Card")

        NavigationView {
            AddEditItemView(
                store: Store(
                    processor: StateProcessor(
                        state: {
                            var copy = cipherState
                            copy.name = "Sample Card"
                            copy.type = .card
                            copy.cardItemState = .init(
                                brand: .custom(.americanExpress),
                                cardholderName: "Bitwarden User",
                                cardNumber: "123456789012345",
                                cardSecurityCode: "123",
                                expirationMonth: .custom(.feb),
                                expirationYear: "3009"
                            )
                            copy.folderId = "1"
                            copy.folders = [
                                .custom(FolderView(id: "1", name: "Financials", revisionDate: Date())),
                            ]
                            copy.isFavoriteOn = false
                            copy.isMasterPasswordRePromptOn = true
                            copy.owner = .personal(email: "security@bitwarden.com")
                            return copy.addEditState
                        }()
                    )
                )
            )
        }
        .previewDisplayName("Edit Card")

        NavigationView {
            AddEditItemView(
                store: Store(
                    processor: StateProcessor(
                        state: cipherState.addEditState
                    )
                )
            )
        }
        .previewDisplayName("Edit Login")

        NavigationView {
            AddEditItemView(
                store: Store(
                    processor: StateProcessor(
                        state: {
                            var state = cipherState
                            state.loginState.totpState = .init("JBSWY3DPEHPK3PXP")
                            state.toast = Toast(title: "Authenticator key added.")
                            return state
                        }()
                    )
                )
            )
        }
        .previewDisplayName("Edit Login: Key Added")
    }
}
#endif // swiftlint:disable:this file_length
