import BitwardenResources
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
                cancelToolbarItem {
                    store.send(.dismissPressed)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    toolbarButton(Localizations.move) {
                        await store.perform(.moveCipher)
                    }
                    .accessibilityIdentifier("MoveButton")
                }
            }
    }

    // MARK: Private Views

    /// The section containing the collections for the organizations.
    private var collectionsSections: some View {
        SectionView(Localizations.collections, contentSpacing: 8) {
            ContentBlock {
                ForEach(store.state.collectionsForOwner, id: \.id) { collection in
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
        }
    }

    /// The content displayed in the view.
    @ViewBuilder private var content: some View {
        if store.state.ownershipOptions.isEmpty {
            Text(Localizations.noOrgsToList)
                .styleGuide(.body)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
                .padding(16)
                .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 16) {
                organizationSection

                collectionsSections
            }
        }
    }

    /// The section containing the organization selection menu.
    @ViewBuilder private var organizationSection: some View {
        if let owner = store.state.owner {
            BitwardenMenuField(
                title: Localizations.organization,
                footer: Localizations.moveToOrgDesc,
                accessibilityIdentifier: "OrganizationListDropdown",
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

#if DEBUG
#Preview("Empty Organizations") {
    NavigationView {
        MoveToOrganizationView(
            store: Store(
                processor: StateProcessor(
                    state: MoveToOrganizationState(
                        cipher: .fixture()
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
                        ],
                        organizationId: "1",
                        ownershipOptions: [.organization(id: "1", name: "Organization")]
                    )
                )
            )
        )
    }
}
#endif
