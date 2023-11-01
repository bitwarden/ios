import SwiftUI

// MARK: - VaultGroupView

/// A view that displays a single vault group.
struct VaultGroupView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultGroupState, VaultGroupAction, VaultGroupEffect>

    var body: some View {
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
                .background(Asset.Colors.backgroundGroupedElevatedSecondary.swiftUIColor)
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
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(store.state.group.navigationTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    store.send(.addItemPressed)
                } label: {
                    Label {
                        Text(Localizations.add)
                    } icon: {
                        Asset.Images.plus.swiftUIImage
                    }
                }
            }
        }
        .task {
            await store.perform(.appeared)
        }
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
