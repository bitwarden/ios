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
        .task { await store.perform(.appeared) }
        .task { await store.perform(.fetchCipherOptions) }
        .toast(store.binding(
            get: \.toast,
            send: AddEditItemAction.toastShown
        ))
    }

    private var addView: some View {
        content
            .navigationTitle(Localizations.addItem)
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
        ScrollView {
            VStack(spacing: 20) {
                if isPolicyEnabled {
                    InfoContainer(Localizations.personalOwnershipPolicyInEffect)
                        .accessibilityIdentifier("PersonalOwnershipPolicyLabel")
                }

                informationSection
                miscellaneousSection
                notesSection
                customSection
                ownershipSection
            }
            .padding(16)
        }
        .animation(.default, value: store.state.collectionsForOwner)
        .dismissKeyboardImmediately()
        .background(
            Asset.Colors.backgroundPrimary.swiftUIColor
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }

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

    private var existing: some View {
        content
            .navigationTitle(Localizations.editItem)
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
                        isCollectionsEnabled: store.state.cipher.organizationId != nil,
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

    private var informationSection: some View {
        SectionView(Localizations.itemInformation) {
            if case .add = store.state.configuration, store.state.allowTypeSelection {
                BitwardenMenuField(
                    title: Localizations.type,
                    accessibilityIdentifier: "ItemTypePicker",
                    options: CipherType.canCreateCases,
                    selection: store.binding(
                        get: \.type,
                        send: AddEditItemAction.typeChanged
                    )
                )
            }

            BitwardenTextField(
                title: Localizations.name,
                text: store.binding(
                    get: \.name,
                    send: AddEditItemAction.nameChanged
                ),
                accessibilityIdentifier: "ItemNameEntry"
            )

            switch store.state.type {
            case .card:
                cardItems
            case .login:
                loginItems
            case .secureNote:
                EmptyView()
            case .identity:
                identityItems
            case .sshKey:
                sshKeyItems
            }
        }
    }

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

    @ViewBuilder private var loginItems: some View {
        AddEditLoginItemView(
            store: store.child(
                state: { addEditState in
                    addEditState.loginState
                },
                mapAction: { $0 },
                mapEffect: { $0 }
            )
        )
    }

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

private extension AddEditItemView {
    var miscellaneousSection: some View {
        SectionView(Localizations.miscellaneous) {
            BitwardenMenuField(
                title: Localizations.folder,
                options: store.state.folders,
                selection: store.binding(
                    get: \.folder,
                    send: AddEditItemAction.folderChanged
                )
            )
            .accessibilityIdentifier("FolderPicker")

            Toggle(Localizations.favorite, isOn: store.binding(
                get: \.isFavoriteOn,
                send: AddEditItemAction.favoriteChanged
            ))
            .toggleStyle(.bitwarden)
            .accessibilityIdentifier("ItemFavoriteToggle")
            if store.state.showMasterPasswordReprompt {
                Toggle(isOn: store.binding(
                    get: \.isMasterPasswordRePromptOn,
                    send: AddEditItemAction.masterPasswordRePromptChanged
                )) {
                    HStack(alignment: .center, spacing: 4) {
                        Text(Localizations.passwordPrompt)
                        Button {
                            openURL(ExternalLinksConstants.protectIndividualItems)
                        } label: {
                            Asset.Images.questionCircle.swiftUIImage
                        }
                        .foregroundColor(Asset.Colors.iconSecondary.swiftUIColor)
                        .accessibilityLabel(Localizations.masterPasswordRePromptHelp)
                    }
                }
                .toggleStyle(.bitwarden)
                .accessibilityIdentifier("MasterPasswordRepromptToggle")
            }
        }
    }

    var notesSection: some View {
        SectionView(Localizations.notes) {
            BitwardenMultilineTextField(
                text: store.binding(
                    get: \.notes,
                    send: AddEditItemAction.notesChanged
                )
            )
            .accessibilityLabel(Localizations.notes)
        }
    }

    @ViewBuilder var ownershipSection: some View {
        if store.state.configuration.isAdding, let owner = store.state.owner {
            SectionView(Localizations.ownership) {
                BitwardenMenuField(
                    title: Localizations.whoOwnsThisItem,
                    accessibilityIdentifier: "ItemOwnershipPicker",
                    options: store.state.ownershipOptions,
                    selection: store.binding(
                        get: { _ in owner },
                        send: AddEditItemAction.ownerChanged
                    )
                )
            }

            if !owner.isPersonal {
                SectionView(Localizations.collections) {
                    if store.state.collectionsForOwner.isEmpty {
                        Text(Localizations.noCollectionsToList)
                            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                            .multilineTextAlignment(.leading)
                            .styleGuide(.body)
                    } else {
                        ForEach(store.state.collectionsForOwner, id: \.id) { collection in
                            if let collectionId = collection.id {
                                Toggle(isOn: store.binding(
                                    get: { _ in store.state.collectionIds.contains(collectionId) },
                                    send: { .collectionToggleChanged($0, collectionId: collectionId) }
                                )) {
                                    Text(collection.name)
                                }
                                .toggleStyle(.bitwarden)
                                .accessibilityIdentifier("CollectionItemCell")
                            }
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
private let multilineText =
    """
    I should really keep this safe.
    Is that right?
    """

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
                            copy.notes = multilineText
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
