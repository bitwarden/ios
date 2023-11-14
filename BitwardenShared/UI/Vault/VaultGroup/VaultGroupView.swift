import SwiftUI

// MARK: - VaultGroupView

/// A view that displays the items in a single vault group.
struct VaultGroupView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultGroupState, VaultGroupAction, VaultGroupEffect>

    var body: some View {
        contents
            .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
            .navigationTitle(store.state.group.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    AddItemButton {
                        store.send(.addItemPressed)
                    }
                }
            }
            .task {
                await store.perform(.appeared)
            }
    }

    // MARK: Private Properties

    @ViewBuilder private var contents: some View {
        if store.state.items.isEmpty {
            emptyView
        } else {
            groupView
        }
    }

    /// A view that displays an empty state for this vault group.
    @ViewBuilder private var emptyView: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()

                    Text(Localizations.noItems)
                        .multilineTextAlignment(.center)
                        .font(.styleGuide(.callout))
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                    Button(Localizations.addAnItem) {
                        store.send(.addItemPressed)
                    }
                    .buttonStyle(.tertiary())

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(minHeight: reader.size.height)
            }
        }
    }

    /// A view that displays a list of the contents of this vault group.
    @ViewBuilder private var groupView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Localizations.items.uppercased())
                    Spacer()
                    Text("\(store.state.items.count)")
                }
                .font(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(store.state.items) { item in
                        Button {
                            store.send(.itemPressed(item))
                        } label: {
                            VaultListItemRowView(store: store.child(
                                state: { _ in
                                    VaultListItemRowState(
                                        item: item,
                                        hasDivider: store.state.items.last != item
                                    )
                                },
                                mapAction: { action in
                                    switch action {
                                    case .morePressed:
                                        return .morePressed(item)
                                    }
                                },
                                mapEffect: nil
                            ))
                        }
                    }
                }
                .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(16)
        }
        .searchable(
            text: store.binding(
                get: \.searchText,
                send: VaultGroupAction.searchTextChanged
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Localizations.search
        )
    }
}

// MARK: Previews

#if DEBUG
struct VaultItemListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VaultGroupView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultGroupState()
                    )
                )
            )
        }
        .previewDisplayName("Empty")

        NavigationView {
            VaultGroupView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultGroupState(
                            group: .login,
                            items: [
                                .init(cipherListView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    name: "Example",
                                    subTitle: "email@example.com",
                                    type: .login,
                                    favorite: true,
                                    reprompt: .none,
                                    edit: false,
                                    viewPassword: true,
                                    attachments: 0,
                                    creationDate: Date(),
                                    deletedDate: nil,
                                    revisionDate: Date()
                                ))!,
                                .init(cipherListView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    name: "Example 2",
                                    subTitle: "email2@example.com",
                                    type: .login,
                                    favorite: true,
                                    reprompt: .none,
                                    edit: false,
                                    viewPassword: true,
                                    attachments: 0,
                                    creationDate: Date(),
                                    deletedDate: nil,
                                    revisionDate: Date()
                                ))!,
                            ]
                        )
                    )
                )
            )
        }
        .previewDisplayName("Logins")
    }
}
#endif
