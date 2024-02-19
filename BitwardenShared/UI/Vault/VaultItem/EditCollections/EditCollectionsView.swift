import BitwardenSdk
import SwiftUI

// MARK: - EditCollectionsView

/// A view that allows the user to move a cipher between collections.
///
struct EditCollectionsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<EditCollectionsState, EditCollectionsAction, EditCollectionsEffect>

    // MARK: View

    var body: some View {
        content
            .navigationBar(title: Localizations.collections, titleDisplayMode: .inline)
            .scrollView()
            .task { await store.perform(.fetchCipherOptions) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    toolbarButton(Localizations.save) {
                        await store.perform(.save)
                    }
                }

                cancelToolbarItem {
                    store.send(.dismissPressed)
                }
            }
    }

    // MARK: Private Views

    /// The content displayed in the view.
    @ViewBuilder private var content: some View {
        if store.state.collections.isEmpty {
            Text(Localizations.noCollectionsToList)
                .styleGuide(.body)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
                .padding(16)
                .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 16) {
                ForEach(store.state.collections, id: \.id) { collection in
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
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Previews

#Preview("Collections") {
    NavigationView {
        EditCollectionsView(
            store: Store(
                processor: StateProcessor(
                    state: EditCollectionsState(
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
                        ]
                    )
                )
            )
        )
    }
}
