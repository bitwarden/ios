import SwiftUI

// MARK: - VaultGroupView

/// A view that displays the items in a single vault group.
struct VaultGroupView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultGroupState, VaultGroupAction, VaultGroupEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        LoadingView(
            state: store.state.loadingState,
            contents: { items in
                if items.isEmpty {
                    emptyView
                } else {
                    groupView(with: items)
                }
            }
        )
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .searchable(
            text: store.binding(
                get: \.searchText,
                send: VaultGroupAction.searchTextChanged
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Localizations.search
        )
        .navigationTitle(store.state.group.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            addToolbarItem {
                store.send(.addItemPressed)
            }
        }
        .task {
            await store.perform(.appeared)
        }
        .task {
            await store.perform(.streamShowWebIcons)
        }
        .toast(store.binding(
            get: \.toast,
            send: VaultGroupAction.toastShown
        ))
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
    }

    // MARK: Private Views

    /// A view that displays an empty state for this vault group.
    @ViewBuilder private var emptyView: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()

                    Text(Localizations.noItems)
                        .multilineTextAlignment(.center)
                        .styleGuide(.callout)
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

    // MARK: Private Methods

    /// A view that displays a list of the contents of this vault group.
    @ViewBuilder
    private func groupView(with items: [VaultListItem]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Localizations.items.uppercased())
                    Spacer()
                    Text("\(items.count)")
                }
                .font(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(items) { item in
                        Button {
                            store.send(.itemPressed(item))
                        } label: {
                            VaultListItemRowView(
                                store: store.child(
                                    state: { state in
                                        VaultListItemRowState(
                                            iconBaseURL: state.iconBaseURL,
                                            item: item,
                                            hasDivider: items.last != item,
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
                                    mapEffect: nil
                                ),
                                timeProvider: timeProvider
                            )
                        }
                    }
                }
                .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(16)
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview("Loading") {
    NavigationView {
        VaultGroupView(
            store: Store(
                processor: StateProcessor(
                    state: VaultGroupState(
                        loadingState: .loading,
                        vaultFilterType: .allVaults
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}

#Preview("Empty") {
    NavigationView {
        VaultGroupView(
            store: Store(
                processor: StateProcessor(
                    state: VaultGroupState(
                        loadingState: .data([]),
                        vaultFilterType: .allVaults
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}

#Preview("Logins") {
    NavigationView {
        VaultGroupView(
            store: Store(
                processor: StateProcessor(
                    state: VaultGroupState(
                        group: .login,
                        loadingState: .data([
                            .init(cipherView: .init(
                                id: UUID().uuidString,
                                organizationId: nil,
                                folderId: nil,
                                collectionIds: [],
                                key: nil,
                                name: "Example",
                                notes: nil,
                                type: .login,
                                login: .init(
                                    username: "email@example.com",
                                    password: nil,
                                    passwordRevisionDate: nil,
                                    uris: nil,
                                    totp: nil,
                                    autofillOnPageLoad: nil
                                ),
                                identity: nil,
                                card: nil,
                                secureNote: nil,
                                favorite: true,
                                reprompt: .none,
                                organizationUseTotp: false,
                                edit: false,
                                viewPassword: true,
                                localData: nil,
                                attachments: [],
                                fields: [],
                                passwordHistory: [],
                                creationDate: Date(),
                                deletedDate: nil,
                                revisionDate: Date()
                            ))!,
                            .init(cipherView: .init(
                                id: UUID().uuidString,
                                organizationId: nil,
                                folderId: nil,
                                collectionIds: [],
                                key: nil,
                                name: "Example 2",
                                notes: nil,
                                type: .login,
                                login: .init(
                                    username: "email2@example.com",
                                    password: nil,
                                    passwordRevisionDate: nil,
                                    uris: nil,
                                    totp: nil,
                                    autofillOnPageLoad: nil
                                ),
                                identity: nil,
                                card: nil,
                                secureNote: nil,
                                favorite: true,
                                reprompt: .none,
                                organizationUseTotp: false,
                                edit: false,
                                viewPassword: true,
                                localData: nil,
                                attachments: [],
                                fields: [],
                                passwordHistory: [],
                                creationDate: Date(),
                                deletedDate: nil,
                                revisionDate: Date()
                            ))!,
                        ]),
                        vaultFilterType: .allVaults
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}
#endif
