import BitwardenResources
import SwiftUI

// MARK: - StepperField

/// The data necessary for displaying a `StepperFieldView`.
///
public struct StepperField<State>: Equatable, Identifiable {
    // MARK: Properties

    /// The accessibility id for the stepper. The `id` will be used as the accessibility id
    /// if this is `nil`.
    let accessibilityId: String?

    /// A key path for updating the backing value for the stepper field.
    public let keyPath: WritableKeyPath<State, Int>

    /// The range of allowable values for the stepper.
    public let range: ClosedRange<Int>

    /// The title of the field.
    public let title: String

    /// The current stepper value.
    public let value: Int

    // MARK: Identifiable

    public var id: String {
        "StepperField-\(title)"
    }

    // MARK: Initializers

    /// Initializes a `StepperField`.
    ///
    /// - Parameters:
    ///   - accessibilityId: The accessibility ID for the stepper.
    ///     The `id` will be used as the accessibility ID if this is `nil`.
    ///   - keyPath: A key path for updating the backing value for the stepper field.
    ///   - range: The range of allowable values for the stepper.
    ///   - title: The title of the field.
    ///   - value: The current stepper value.
    public init(
        accessibilityId: String?,
        keyPath: WritableKeyPath<State, Int>,
        range: ClosedRange<Int>,
        title: String,
        value: Int,
    ) {
        self.accessibilityId = accessibilityId
        self.keyPath = keyPath
        self.range = range
        self.title = title
        self.value = value
    }
}

// MARK: - StepperFieldView

/// A view that displays a stepper for display in a form.
///
public struct StepperFieldView<State>: View {
    // MARK: Properties

    /// A closure containing the action to take when a new value is selected.
    let action: @Sendable (Int) -> Void

    /// The data for displaying the field.
    let field: StepperField<State>

    public var body: some View {
        BitwardenStepper(
            value: Binding(get: { field.value }, set: action),
            in: field.range,
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
    public init(field: StepperField<State>, action: @Sendable @escaping (Int) -> Void) {
        self.action = action
        self.field = field
    }
}
