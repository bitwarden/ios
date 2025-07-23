import BitwardenResources
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
                cancelToolbarItem {
                    store.send(.dismissPressed)
                }

                saveToolbarItem {
                    await store.perform(.save)
                }
            }
    }

    // MARK: Private Views

    /// The content displayed in the view.
    @ViewBuilder private var content: some View {
        if store.state.collections.isEmpty {
            Text(Localizations.noCollectionsToList)
                .styleGuide(.body)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
                .padding(16)
                .frame(maxWidth: .infinity)
        } else {
            ContentBlock(dividerLeadingPadding: 16) {
                ForEach(store.state.collections, id: \.id) { collection in
                    if let collectionId = collection.id {
                        BitwardenToggle(
                            collection.name,
                            isOn: store.binding(
                                get: { _ in store.state.collectionIds.contains(collectionId) },
                                send: { .collectionToggleChanged($0, collectionId: collectionId) }
                            ),
                            accessibilityIdentifier: "CollectionItemSwitch"
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Collections") {
    NavigationView {
        EditCollectionsView(
            store: Store(
                processor: StateProcessor(
                    state: EditCollectionsState(
                        cipher: .fixture(),
                        collections: [
                            .fixture(
                                id: "1",
                                name: "Design",
                                organizationId: "1"
                            ),
                            .fixture(
                                id: "2",
                                name: "Engineering",
                                organizationId: "1"
                            ),
                        ]
                    )
                )
            )
        )
    }
}
#endif
