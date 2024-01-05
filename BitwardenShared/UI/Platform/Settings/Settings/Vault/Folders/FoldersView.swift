import SwiftUI

// MARK: - FoldersView

/// A view that allows users to view their folders.
///
struct FoldersView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<FoldersState, FoldersAction, FoldersEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if store.state.folders.isEmpty {
                empty
                    .background(Color(asset: Asset.Colors.backgroundSecondary))
            } else {
                folders
                    .scrollView()
            }
        }
        .navigationBar(title: Localizations.folders, titleDisplayMode: .inline)
        .toolbar {
            addToolbarItem {
                store.send(.add)
            }
        }
        .task {
            await store.perform(.streamFolders)
        }
        .toast(store.binding(
            get: \.toast,
            send: FoldersAction.toastShown
        ))
    }

    // MARK: Private views

    /// The empty state for when the user doesn't have any folders yet.
    private var empty: some View {
        Text(Localizations.noFoldersToList)
            .styleGuide(.callout)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The section listing all the user's folders.
    private var folders: some View {
        VStack(spacing: 0) {
            ForEachIndexed(store.state.folders, id: \.id) { index, folder in
                SettingsListItem(folder.name, hasDivider: index < (store.state.folders.count - 1)) {
                    store.send(.folderTapped(id: folder.id))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
