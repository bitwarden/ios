import BitwardenKit
import SwiftUI

/// A view that showcases the `DateFieldPicker` component for manual testing.
///
struct DateFieldPickerShowcaseView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<
        DateFieldPickerShowcaseState,
        DateFieldPickerShowcaseAction,
        DateFieldPickerShowcaseEffect,
    >

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Private Views

    /// The main content view.
    private var content: some View {
        Form {
            Section {
                DateFieldPicker(
                    title: Localizations.dateOfBirth,
                    date: store.binding(
                        get: \.selectedDate,
                        send: DateFieldPickerShowcaseAction.dateChanged,
                    ),
                    footer: Localizations.dateFieldPickerDescription,
                )
            } header: {
                Text(Localizations.dateField)
            }

            Section {
                if let selectedDate = store.state.selectedDate {
                    Text(Localizations.selectedDateValue(selectedDate.formatted(date: .long, time: .omitted)))
                        .styleGuide(.body)
                } else {
                    Text(Localizations.noDateSelected)
                        .foregroundColor(.secondary)
                        .styleGuide(.body)
                }
            } header: {
                Text(Localizations.formValues)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        DateFieldPickerShowcaseView(
            store: Store(processor: StateProcessor(state: DateFieldPickerShowcaseState())),
        )
    }
}
#endif
