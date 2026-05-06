import BitwardenResources
import SwiftUI

// MARK: - AutofillAssistPicker

/// A menu button that lets the user map a cipher field (e.g. username or password) to a specific
/// page field detected by the Action Extension. Used inside `AddEditLoginItemView` when
/// `pageDetails` are available.
///
struct AutofillAssistPicker: View {
    // MARK: Properties

    /// The accessibility label for the button (e.g. "Select page field for username").
    let accessibilityLabel: String

    /// The accessibility identifier for the button.
    let accessibilityIdentifier: String

    /// The selectable page fields to display in the menu.
    let pageFields: [AutofillAssistFieldOption]

    /// The opId of the currently selected field, or `nil` when using heuristic detection.
    let selectedOpId: String?

    /// Called when the user selects a field, passing the chosen opId, or `nil` for "None (Auto)".
    let onSelect: (String?) -> Void

    // MARK: View

    var body: some View {
        Menu {
            Button {
                onSelect(nil)
            } label: {
                Label {
                    Text(Localizations.autofillAssistNone)
                } icon: {
                    if selectedOpId == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Divider()
            ForEach(pageFields) { field in
                Button {
                    onSelect(field.opId)
                } label: {
                    Label {
                        Text(field.displayLabel)
                    } icon: {
                        if selectedOpId == field.opId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            SharedAsset.Icons.link16.swiftUIImage
                .imageStyle(.accessoryIcon16)
                .opacity(selectedOpId != nil ? 1.0 : 0.4)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
