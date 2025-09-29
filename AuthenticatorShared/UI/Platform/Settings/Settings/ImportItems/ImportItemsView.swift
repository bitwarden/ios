import BitwardenResources
import SwiftUI

// MARK: - ImportItemsView

/// A view that allows users to import their items.
///
struct ImportItemsView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<ImportItemsState, ImportItemsAction, ImportItemsEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            fileFormatField

            importButton
        }
        .scrollView()
        .navigationBar(title: Localizations.importItems, titleDisplayMode: .inline)
        .task {
            await store.perform(.loadData)
        }
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
        .toast(store.binding(
            get: \.toast,
            send: ImportItemsAction.toastShown
        ))
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private Views

    /// The button to import the items.
    private var importButton: some View {
        Button(Localizations.importItems) {
            store.send(.importItemsTapped)
        }
        .buttonStyle(.tertiary())
        .accessibilityIdentifier("ImportItemsButton")
    }

    /// The selector to choose the import file format.
    private var fileFormatField: some View {
        BitwardenMenuField(
            title: Localizations.fileFormat,
            accessibilityIdentifier: "FileFormatPicker",
            options: ImportFormatType.allCases,
            selection: store.binding(
                get: \.fileFormat,
                send: ImportItemsAction.fileFormatTypeChanged
            )
        )
    }
}

// MARK: - Previews

#Preview("View") {
    ImportItemsView(store: Store(processor: StateProcessor(state: ImportItemsState())))
}
