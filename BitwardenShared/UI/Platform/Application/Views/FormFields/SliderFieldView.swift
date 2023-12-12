import SwiftUI

// MARK: - SliderField

/// The data necessary for displaying a `SliderFieldView`.
///
struct SliderField<State>: Equatable, Identifiable {
    // MARK: Properties

    /// A key path for updating the backing value for the slider field.
    let keyPath: WritableKeyPath<State, Double>

    /// The range of allowable values for the slider.
    let range: ClosedRange<Double>

    /// The distance between each valid value.
    let step: Double

    /// The title of the field.
    let title: String

    /// The current slider value.
    let value: Double

    // MARK: Identifiable

    var id: String {
        "SliderField-\(title)"
    }
}

// MARK: - SliderFieldView

/// A view that displays a slider for display in a form.
///
struct SliderFieldView<State>: View {
    // MARK: Properties

    /// A closure containing the action to take when a new value is selected.
    let action: (Double) -> Void

    /// The data for displaying the field.
    let field: SliderField<State>

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(field.title)
                    .styleGuide(.body)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                Spacer()

                Text(String(Int(field.value)))
                    .styleGuide(.body, monoSpacedDigit: true)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
            }
            .accessibilityHidden(true)

            Divider()

            Slider(
                value: Binding(get: { field.value }, set: action),
                in: field.range,
                step: field.step
            )
            .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
            .accessibilityLabel(field.title)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .cornerRadius(10)
    }

    // MARK: Initialization

    /// Initialize a `SliderFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when a new value is selected.
    ///
    init(field: SliderField<State>, action: @escaping (Double) -> Void) {
        self.action = action
        self.field = field
    }
}
