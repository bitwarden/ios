import SwiftUI

// MARK: - ToggleField

/// The data necessary for displaying a `ToggleFieldView`.
///
struct ToggleField<State>: Equatable, Identifiable {
    // MARK: Properties

    /// The accessibility label for the toggle. The title will be used as the accessibility label
    /// if this is `nil`.
    let accessibilityLabel: String?

    /// Whether the toggle is disabled.
    let isDisabled: Bool

    /// The current toggle value.
    let isOn: Bool

    /// A key path for updating the backing value for the toggle field.
    let keyPath: WritableKeyPath<State, Bool>

    /// The title of the field.
    let title: String

    // MARK: Identifiable

    var id: String {
        "ToggleField-\(title)"
    }
}

// MARK: - ToggleFieldView

/// A view that displays a toggle for display in a form.
///
struct ToggleFieldView<State>: View {
    // MARK: Properties

    /// A closure containing the action to take when the toggle is toggled.
    let action: (Bool) -> Void

    /// The data for displaying the field.
    let field: ToggleField<State>

    var body: some View {
        VStack(spacing: 0) {
            Toggle(
                field.title,
                isOn: Binding(get: { field.isOn }, set: action)
            )
            .accessibilityLabel(field.accessibilityLabel ?? field.title)
            .disabled(field.isDisabled)
            .toggleStyle(.bitwarden)
            .padding(.bottom, 16)
            .padding(.top, 4)

            Divider()
        }
    }

    // MARK: Initialization

    /// Initialize a `ToggleFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when the toggle is toggled.
    ///
    init(field: ToggleField<State>, action: @escaping (Bool) -> Void) {
        self.action = action
        self.field = field
    }
}
