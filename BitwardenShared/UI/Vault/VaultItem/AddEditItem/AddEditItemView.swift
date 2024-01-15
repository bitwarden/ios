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

    var body: some View {
        Group {
            switch store.state.configuration {
            case .add:
                addView
            case .existing:
                existing
            }
        }
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
            }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                informationSection
                miscellaneousSection
                notesSection
                customSection
                ownershipSection
                saveButton
            }
            .padding(16)
        }
        .animation(.default, value: store.state.collectionsForOwner)
        .background(
            Asset.Colors.backgroundSecondary.swiftUIColor
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
        SectionView(Localizations.customFields) {
            Button(Localizations.newCustomField) {
                store.send(.newCustomFieldPressed)
            }
            .buttonStyle(.tertiary())
        }
    }

    private var existing: some View {
        content
            .navigationTitle(Localizations.editItem)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
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

                    Button {
                        store.send(.dismissPressed)
                    } label: {
                        Asset.Images.cancel.swiftUIImage
                            .resizable()
                            .frame(width: 19, height: 19)
                    }
                    .accessibilityLabel(Localizations.close)
                }
            }
    }

    private var informationSection: some View {
        SectionView(Localizations.itemInformation) {
            if case .add = store.state.configuration, store.state.allowTypeSelection {
                BitwardenMenuField(
                    title: Localizations.type,
                    options: CipherType.allCases,
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
                )
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

            Toggle(Localizations.favorite, isOn: store.binding(
                get: \.isFavoriteOn,
                send: AddEditItemAction.favoriteChanged
            ))
            .toggleStyle(.bitwarden)

            Toggle(isOn: store.binding(
                get: \.isMasterPasswordRePromptOn,
                send: AddEditItemAction.masterPasswordRePromptChanged
            )) {
                HStack(alignment: .center, spacing: 4) {
                    Text(Localizations.passwordPrompt)
                    Button {
                        openURL(ExternalLinksConstants.protectIndividualItems)
                    } label: {
                        Asset.Images.questionRound.swiftUIImage
                    }
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .accessibilityLabel(Localizations.masterPasswordRePromptHelp)
                }
            }
            .toggleStyle(.bitwarden)
        }
    }

    var notesSection: some View {
        SectionView(Localizations.notes) {
            BitwardenTextField(
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
                            }
                        }
                    }
                }
            }
        }
    }

    var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.savePressed)
        }
        .buttonStyle(.primary())
    }
}

#if DEBUG
private let multilineText =
    """
    I should really keep this safe.
    Is that right?
    """

struct AddEditItemView_Previews: PreviewProvider {
    static var fixedDate: Date {
        .init(timeIntervalSince1970: 1_695_000_000)
    }

    static var cipherState: CipherItemState {
        var state = CipherItemState(
            existing: .init(
                id: .init(),
                organizationId: nil,
                folderId: nil,
                collectionIds: [],
                key: .init(),
                name: "Edit Em",
                notes: nil,
                type: .login,
                login: .init(
                    username: "EddyEddity",
                    password: "changerdanger",
                    passwordRevisionDate: fixedDate,
                    uris: [
                        .init(uri: "yahoo.com", match: nil),
                        .init(uri: "account.yahoo.com", match: nil),
                    ],
                    totp: nil,
                    autofillOnPageLoad: nil
                ),
                identity: nil,
                card: nil,
                secureNote: nil,
                favorite: true,
                reprompt: .none,
                organizationUseTotp: false,
                edit: true,
                viewPassword: true,
                localData: nil,
                attachments: nil,
                fields: nil,
                passwordHistory: nil,
                creationDate: fixedDate,
                deletedDate: nil,
                revisionDate: fixedDate
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
                            state.toast = Toast(text: "Authenticator key added.")
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
