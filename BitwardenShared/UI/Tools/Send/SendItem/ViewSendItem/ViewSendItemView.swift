import SwiftUI

// MARK: - ViewSendItemView

/// A view that allows the user to view the details of a send item.
///
struct ViewSendItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewSendItemState, ViewSendItemAction, ViewSendItemEffect>

    // MARK: View

    var body: some View {
        EmptyView()
            .scrollView(padding: 12)
            .navigationTitle(store.state.navigationTitle)
            .overlay(alignment: .bottomTrailing) {
                editItemFloatingActionButton {
                    store.send(.editItem)
                }
            }
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismiss)
                }
            }
    }
}
