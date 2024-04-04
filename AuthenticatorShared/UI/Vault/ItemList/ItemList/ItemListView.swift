import SwiftUI

// MARK: - ItemListView

/// A view that displays the items in a single vault group.
struct ItemListView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<ItemListState, ItemListAction, ItemListEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        content
            .navigationTitle("Item List")
            .navigationBarTitleDisplayMode(.inline)
            .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
            .toolbar {
                addToolbarItem(hidden: !store.state.showAddToolbarItem) {
                    Task {
                        await store.perform(.addItemPressed)
                    }
                }
            }
            .task {
                await store.perform(.appeared)
            }
    }

    // MARK: Private

    @ViewBuilder private var content: some View {
        LoadingView(state: store.state.loadingState) { items in
            if items.isEmpty {
                emptyView
            } else {
                groupView(with: items)
            }
        }
    }

    /// A view that displays an empty state for this vault group.
    @ViewBuilder private var emptyView: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()

                    Text(store.state.noItemsString)
                        .multilineTextAlignment(.center)
                        .styleGuide(.callout)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                    if store.state.showAddItemButton {
                        Button(Localizations.addAnItem) {
                            Task {
                                await store.perform(.addItemPressed)
                            }
                        }
                        .buttonStyle(.tertiary())
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(minWidth: reader.size.width, minHeight: reader.size.height)
            }
        }
    }

    // MARK: Private Methods

    /// A view that displays a list of the sections within this vault group.
    ///
    @ViewBuilder
    private func groupView(with items: [VaultListItem]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 7) {
                ForEach(items) { item in
                    Button {
                        store.send(.itemPressed(item))
                    } label: {
                        vaultItemRow(
                            for: item,
                            isLastInSection: true
                        )
                    }
                }
                .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(16)
        }
    }

    /// Creates a row in the list for the provided item.
    ///
    /// - Parameters:
    ///   - item: The `VaultListItem` to use when creating the view.
    ///   - isLastInSection: A flag indicating if this item is the last one in the section.
    ///
    @ViewBuilder
    private func vaultItemRow(for item: VaultListItem, isLastInSection: Bool = false) -> some View {
        ItemListItemRowView(
            store: store.child(
                state: { state in
                    ItemListItemRowState(
                        iconBaseURL: state.iconBaseURL,
                        item: item,
                        hasDivider: !isLastInSection,
                        showWebIcons: state.showWebIcons
                    )
                },
                mapAction: { action in
                    switch action {
                    case let .copyTOTPCode(code):
                        return .copyTOTPCode(code)
                    case .morePressed:
                        return .morePressed(item)
                    }
                },
                mapEffect: { .appeared }
            ),
            timeProvider: timeProvider
        )
    }
}

// MARK: Previews

#if DEBUG
#Preview("Loading") {
    NavigationView {
        ItemListView(
            store: Store(
                processor: StateProcessor(
                    state: ItemListState(
                        loadingState: .loading(nil)
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}

#Preview("Tokens") {
    NavigationView {
        ItemListView(
            store: Store(
                processor: StateProcessor(
                    state: ItemListState(
                        loadingState: .data(
                            [
                                .init(
                                    id: "One",
                                    itemType: .totp(
                                        name: "One",
                                        totpModel: VaultListTOTP(
                                            id: UUID().uuidString,
                                            loginView: .init(
                                                username: "email@example.com",
                                                password: nil,
                                                passwordRevisionDate: nil,
                                                uris: nil,
                                                totp: "asdf",
                                                autofillOnPageLoad: nil,
                                                fido2Credentials: nil
                                            ),
                                            totpCode: TOTPCodeModel(
                                                code: "123456",
                                                codeGenerationDate: Date(),
                                                period: 30
                                            )
                                        )
                                    )
                                ),
                                .init(
                                    id: "Two",
                                    itemType: .totp(
                                        name: "Two",
                                        totpModel: VaultListTOTP(
                                            id: UUID().uuidString,
                                            loginView: .init(
                                                username: "email@example.com",
                                                password: nil,
                                                passwordRevisionDate: nil,
                                                uris: nil,
                                                totp: "asdf",
                                                autofillOnPageLoad: nil,
                                                fido2Credentials: nil
                                            ),
                                            totpCode: TOTPCodeModel(
                                                code: "123456",
                                                codeGenerationDate: Date(),
                                                period: 30
                                            )
                                        )
                                    )
                                ),
                            ]
                        )
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}
#endif
