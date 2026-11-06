import BitwardenKit
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
            header

            fileFormatField

            exportButton
        }
        .scrollView()
        .navigationBar(title: Localizations.export, titleDisplayMode: .inline)
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
        Button(Localizations.export) {
            store.send(.exportItemsTapped)
        }
        .buttonStyle(.primary())
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
                send: ExportItemsAction.fileFormatTypeChanged,
            ),
        )
    }

    /// The header describing which items are included in the export.
    private var header: some View {
        VStack(spacing: 12) {
            Text(Localizations.includedInThisReport)
                .styleGuide(.title2, weight: .semibold)
                .accessibilityIdentifier("ExportItemsHeaderTitle")

            Text(Localizations.onlyCodesStoredLocallyOnThisDeviceDescriptionLong)
                .styleGuide(.body)
                .padding(.horizontal, 12)
                .accessibilityIdentifier("ExportItemsHeaderDescription")
        }
        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
}

// MARK: - Previews

#Preview("View") {
    ExportItemsView(store: Store(processor: StateProcessor(state: ExportItemsState())))
}
