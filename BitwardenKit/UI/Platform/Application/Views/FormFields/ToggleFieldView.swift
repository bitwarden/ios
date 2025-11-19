import SwiftUI

// MARK: - ToggleField

/// The data necessary for displaying a `ToggleFieldView`.
///
public struct ToggleField<State>: Equatable, Identifiable {
    // MARK: Properties

    /// The accessibility id for the toggle. The `id` will be used as the accessibility id
    /// if this is `nil`.
    let accessibilityId: String?

    /// The accessibility label for the toggle. The title will be used as the accessibility label
    /// if this is `nil`.
    let accessibilityLabel: String?

    /// Whether the toggle is disabled.
    let isDisabled: Bool

    /// The current toggle value.
    public let isOn: Bool

    /// A key path for updating the backing value for the toggle field.
    public let keyPath: WritableKeyPath<State, Bool>

    /// The title of the field.
    public let title: String

    // MARK: Identifiable

    public var id: String {
        "ToggleField-\(title)"
    }

    // MARK: Initializer

    /// Initializes a `ToggleField`.
    ///
    /// - Parameters:
    ///   - accessibilityId: The accessibility ID for the toggle.
    ///     The `id` will be used as the accessibility ID if this is `nil`.
    ///   - accessibilityLabel: The accessibility label for the toggle.
    ///     The title will be used as the accessibility label if this is `nil`.
    ///   - isDisabled: Whether the toggle is disabled.
    ///   - isOn: The current toggle value.
    ///   - keyPath: A key path for updating the backing value for the toggle field.
    ///   - title: The title of the field.
    public init(
        accessibilityId: String?,
        accessibilityLabel: String?,
        isDisabled: Bool,
        isOn: Bool,
        keyPath: WritableKeyPath<State, Bool>,
        title: String,
    ) {
        self.accessibilityId = accessibilityId
        self.accessibilityLabel = accessibilityLabel
        self.isDisabled = isDisabled
        self.isOn = isOn
        self.keyPath = keyPath
        self.title = title
    }
}

// MARK: - ToggleFieldView

/// A view that displays a toggle for display in a form.
///
public struct ToggleFieldView<State>: View {
    // MARK: Properties

    /// A closure containing the action to take when the toggle is toggled.
    let action: @Sendable (Bool) -> Void

    /// The data for displaying the field.
    let field: ToggleField<State>

    public var body: some View {
        Toggle(
            field.title,
            isOn: Binding(get: { field.isOn }, set: action),
        )
        .accessibilityIdentifier(field.accessibilityId ?? field.id)
        .accessibilityLabel(field.accessibilityLabel ?? field.title)
        .disabled(field.isDisabled)
        .toggleStyle(.bitwarden)
        .padding(16)
    }

    // MARK: Initialization

    /// Initialize a `ToggleFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when the toggle is toggled.
    ///
    public init(field: ToggleField<State>, action: @Sendable @escaping (Bool) -> Void) {
        self.action = action
        self.field = field
    }
}
