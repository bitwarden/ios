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
                    .background(Color(asset: Asset.Colors.backgroundPrimary))
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
        .overlay(alignment: .bottomTrailing) {
            addItemFloatingActionButton {
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
            .accessibilityIdentifier("NoFoldersLabel")
    }

    /// The section listing all the user's folders.
    private var folders: some View {
        VStack(spacing: 0) {
            ForEachIndexed(
                store.state.folders.sorted { first, second in
                    if first.name.localizedStandardCompare(second.name) == .orderedSame {
                        first.id?.localizedStandardCompare(second.id ?? "") == .orderedAscending
                    } else {
                        first.name.localizedStandardCompare(second.name) == .orderedAscending
                    }
                },
                id: \.id
            ) { index, folder in
                SettingsListItem(
                    folder.name,
                    hasDivider: index < (store.state.folders.count - 1),
                    nameAccessibilityID: "FolderName"
                ) {
                    guard let id = folder.id else { return }
                    store.send(.folderTapped(id: id))
                }
                .accessibilityIdentifier("FolderCell")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.bottom, FloatingActionButton.bottomOffsetPadding)
    }
}

#if DEBUG
#Preview {
    FoldersView(
        store: Store(
            processor: StateProcessor(
                state: .init(
                    folders: [
                        .init(
                            id: "1",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "2",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "3",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "4",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "5",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "6",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "7",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "8",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "9",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "10",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "11",
                            name: "Test",
                            revisionDate: .now
                        ),
                        .init(
                            id: "12",
                            name: "Test",
                            revisionDate: .now
                        ),
                    ]
                )
            )
        )
    )
}
#endif
