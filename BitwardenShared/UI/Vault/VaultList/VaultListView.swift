import SwiftUI

// MARK: - VaultListView

/// A view that allows the user to view a list of the items in their vault.
///
struct VaultListView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultListState, VaultListAction, Void>

    var body: some View {
        empty
            .searchable(
                text: store.binding(
                    get: \.searchText,
                    send: VaultListAction.searchTextChanged
                ),
                prompt: Localizations.search
            )
            .navigationTitle(Localizations.myVault)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        store.send(.profilePressed)
                    } label: {
                        Text(store.state.userInitials)
                            .font(.styleGuide(.caption2))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.purple)
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addItemPressed)
                    } label: {
                        Label {
                            Text(Localizations.addAnItem)
                        } icon: {
                            Asset.Images.plus.swiftUIImage
                                .resizable()
                                .frame(width: 19, height: 19)
                        }
                    }
                }
            }
    }

    // MARK: Private Properties

    /// The empty state for this view, displayed when there are no items in the vault.
    @ViewBuilder private var empty: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()

                    Text(Localizations.noItems)
                        .multilineTextAlignment(.center)

                    Button(Localizations.addAnItem) {
                        store.send(.addItemPressed)
                    }
                    .buttonStyle(.tertiary())

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(minHeight: reader.size.height)
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        }
    }
}

// MARK: Previews

struct VaultListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            userInitials: "AA"
                        )
                    )
                )
            )
        }
        .previewDisplayName("Empty")
    }
}
