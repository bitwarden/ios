import BitwardenResources
import SwiftUI

// MARK: - StepperField

/// The data necessary for displaying a `StepperFieldView`.
///
struct StepperField<State>: Equatable, Identifiable {
    // MARK: Properties

    /// The accessibility id for the stepper. The `id` will be used as the accessibility id
    /// if this is `nil`.
    let accessibilityId: String?

    /// A key path for updating the backing value for the stepper field.
    let keyPath: WritableKeyPath<State, Int>

    /// The range of allowable values for the stepper.
    let range: ClosedRange<Int>

    /// The title of the field.
    let title: String

    /// The current stepper value.
    let value: Int

    // MARK: Identifiable

    var id: String {
        "StepperField-\(title)"
    }
}

// MARK: - StepperFieldView

/// A view that displays a stepper for display in a form.
///
struct StepperFieldView<State>: View {
    // MARK: Properties

    /// A closure containing the action to take when a new value is selected.
    let action: (Int) -> Void

    /// The data for displaying the field.
    let field: StepperField<State>

    var body: some View {
        BitwardenStepper(
            value: Binding(get: { field.value }, set: action),
            in: field.range
        ) {
            Text(field.title)
                .styleGuide(.body)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
        }
        .accessibilityIdentifier(field.accessibilityId ?? field.id)
    }

    // MARK: Initialization

    /// Initialize a `StepperFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when a new value is selected.
    ///
    init(field: StepperField<State>, action: @escaping (Int) -> Void) {
        self.action = action
        self.field = field
    }
}
