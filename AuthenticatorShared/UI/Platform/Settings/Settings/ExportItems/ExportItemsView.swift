import BitwardenResources
import SwiftUI

// MARK: - ExportItemsView

/// A view that allows users to export their items.
///
struct ExportItemsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ExportItemsState, ExportItemsAction, ExportItemsEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            fileFormatField

            exportButton
        }
        .scrollView()
        .navigationBar(title: Localizations.exportItems, titleDisplayMode: .inline)
        .task {
            await store.perform(.loadData)
        }
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private Views

    /// The button to export the items.
    private var exportButton: some View {
        Button(Localizations.exportItems) {
            store.send(.exportItemsTapped)
        }
        .buttonStyle(.tertiary())
        .accessibilityIdentifier("ExportItemsButton")
    }

    /// The selector to choose the export file format.
    private var fileFormatField: some View {
        BitwardenMenuField(
            title: Localizations.fileFormat,
            accessibilityIdentifier: "FileFormatPicker",
            options: ExportFormatType.allCases,
            selection: store.binding(
                get: \.fileFormat,
                send: ExportItemsAction.fileFormatTypeChanged
            )
        )
    }
}

// MARK: - Previews

#Preview("View") {
    ExportItemsView(store: Store(processor: StateProcessor(state: ExportItemsState())))
}
