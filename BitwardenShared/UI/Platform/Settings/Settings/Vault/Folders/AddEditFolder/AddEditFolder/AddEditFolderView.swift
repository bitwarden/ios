import BitwardenResources
import SwiftUI

// MARK: - AddEditFolderView

/// A view that allows users to add a new folder or edit an existing one.
///
struct AddEditFolderView: View {
    // MARK: Properties

    /// The store that renders the view.
    @ObservedObject var store: Store<AddEditFolderState, AddEditFolderAction, AddEditFolderEffect>

    // MARK: View

    var body: some View {
        switch store.state.mode {
        case .add:
            addView
        case .edit:
            editView
        }
    }

    // MARK: Private views

    /// The view to add a new folder.
    private var addView: some View {
        content
            .navigationBar(title: Localizations.addFolder, titleDisplayMode: .inline)
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismiss)
                }

                saveToolbarItem {
                    await store.perform(.saveTapped)
                }
            }
    }

    /// The view to edit an existing folder.
    private var editView: some View {
        content
            .navigationBar(title: Localizations.editFolder, titleDisplayMode: .inline)
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismiss)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    saveToolbarButton {
                        await store.perform(.saveTapped)
                    }

                    optionsToolbarMenu {
                        AsyncButton(Localizations.delete, role: .destructive) {
                            await store.perform(.deleteTapped)
                        }
                    }
                }
            }
    }

    /// The content of the view in either mode.
    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            nameEntryTextField
        }
        .scrollView()
    }

    /// The name entry text field.
    private var nameEntryTextField: some View {
        BitwardenTextField(
            title: Localizations.name,
            text: store.binding(
                get: \.folderName,
                send: AddEditFolderAction.folderNameTextChanged
            )
        )
    }
}
