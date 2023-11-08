import SwiftUI

// MARK: - SendListView

/// A view that allows the user to view a list of the send items.
///
struct SendListView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<SendListState, SendListAction, Void>

    // MARK: View

    var body: some View {
        empty
            .searchable(
                text: store.binding(
                    get: \.searchText,
                    send: SendListAction.searchTextChanged
                ),
                prompt: Localizations.search
            )
            .navigationTitle(Localizations.send)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        store.send(.infoButtonPressed)
                    } label: {
                        Image(asset: Asset.Images.info)
                            .resizable()
                            .frame(width: 19, height: 19)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
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

    // MARK: Private views

    /// The empty state for this view, displayed when there are no items.
    @ViewBuilder private var empty: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()

                    Text(Localizations.noSends)
                        .multilineTextAlignment(.center)

                    Button(Localizations.addASend) {
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

struct SendListView_Previews: PreviewProvider {
    static var previews: some View {
        SendListView(
            store: Store(
                processor: StateProcessor(state: SendListState())
            )
        )
    }
}
