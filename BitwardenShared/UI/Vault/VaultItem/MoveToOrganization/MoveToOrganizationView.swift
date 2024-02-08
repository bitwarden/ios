import BitwardenSdk
import SwiftUI

// MARK: - MoveToOrganizationView

/// A view that allows the user to move a cipher to an organization.
///
struct MoveToOrganizationView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<MoveToOrganizationState, MoveToOrganizationAction, MoveToOrganizationEffect>

    // MARK: View

    var body: some View {
        content
            .navigationBar(title: Localizations.moveToOrganization, titleDisplayMode: .inline)
            .scrollView()
            .task { await store.perform(.fetchCipherOptions) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    toolbarButton(Localizations.move) {
                        await store.perform(.moveCipher)
                    }
                }

                cancelToolbarItem {
                    store.send(.dismissPressed)
                }
            }
    }

    // MARK: Private Views

    /// The section containing the collections for the organizations.
    private var collectionsSections: some View {
        SectionView(Localizations.collections) {
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

    /// The content displayed in the view.
    @ViewBuilder private var content: some View {
        if store.state.ownershipOptions.isEmpty {
            Text(Localizations.noOrgsToList)
                .styleGuide(.body)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
                .padding(16)
                .frame(maxWidth: .infinity)
        } else {
            organizationSection

            collectionsSections
        }
    }

    /// The section containing the organization selection menu.
    @ViewBuilder private var organizationSection: some View {
        if let owner = store.state.owner {
            BitwardenMenuField(
                title: Localizations.organization,
                footer: Localizations.moveToOrgDesc,
                options: store.state.ownershipOptions,
                selection: store.binding(
                    get: { _ in owner },
                    send: MoveToOrganizationAction.ownerChanged
                )
            )
        }
    }
}

// MARK: - Previews

#Preview("Empty Organizations") {
    NavigationView {
        MoveToOrganizationView(
            store: Store(
                processor: StateProcessor(
                    state: MoveToOrganizationState(
                        cipher: CipherView(
                            id: nil,
                            organizationId: nil,
                            folderId: nil,
                            collectionIds: [],
                            key: nil,
                            name: "",
                            notes: nil,
                            type: .login,
                            login: nil,
                            identity: nil,
                            card: nil,
                            secureNote: nil,
                            favorite: false,
                            reprompt: .none,
                            organizationUseTotp: false,
                            edit: true,
                            viewPassword: true,
                            localData: nil,
                            attachments: nil,
                            fields: nil,
                            passwordHistory: nil,
                            creationDate: Date(),
                            deletedDate: nil,
                            revisionDate: Date()
                        )
                    )
                )
            )
        )
    }
}

#Preview("Organizations") {
    NavigationView {
        MoveToOrganizationView(
            store: Store(
                processor: StateProcessor(
                    state: MoveToOrganizationState(
                        cipher: CipherView(
                            id: nil,
                            organizationId: nil,
                            folderId: nil,
                            collectionIds: [],
                            key: nil,
                            name: "",
                            notes: nil,
                            type: .login,
                            login: nil,
                            identity: nil,
                            card: nil,
                            secureNote: nil,
                            favorite: false,
                            reprompt: .none,
                            organizationUseTotp: false,
                            edit: true,
                            viewPassword: true,
                            localData: nil,
                            attachments: nil,
                            fields: nil,
                            passwordHistory: nil,
                            creationDate: Date(),
                            deletedDate: nil,
                            revisionDate: Date()
                        ),
                        collections: [
                            CollectionView(
                                id: "1",
                                organizationId: "1",
                                name: "Design",
                                externalId: nil,
                                hidePasswords: false,
                                readOnly: false
                            ),
                            CollectionView(
                                id: "2",
                                organizationId: "1",
                                name: "Engineering",
                                externalId: nil,
                                hidePasswords: false,
                                readOnly: false
                            ),
                        ],
                        organizationId: "1",
                        ownershipOptions: [.organization(id: "1", name: "Organization")]
                    )
                )
            )
        )
    }
}
