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

    /// The accessibility id for the slider. The `title` will be used as the accessibility id
    /// if this is `nil`.
    let sliderAccessibilityId: String?

    /// The accessibility id for the slider value. The `id` will be used as the accessibility id
    /// if this is `nil`.
    let sliderValueAccessibilityId: String?

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

    /// The data for displaying the field.
    let field: SliderField<State>

    /// A closure containing the action to take when the slider begins or ends editing.
    let onEditingChanged: (Bool) -> Void

    /// A closure containing the action to take when a new value is selected.
    let onValueChanged: (Double) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(field.title)
                .styleGuide(.body)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .accessibilityHidden(true)

            BitwardenSlider(
                value: Binding(get: { field.value }, set: onValueChanged),
                in: field.range,
                step: field.step,
                onEditingChanged: onEditingChanged
            ) {
                Circle()
                    .fill(Asset.Colors.sliderFilled.swiftUIColor)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(Asset.Colors.sliderThumbBorder.swiftUIColor, lineWidth: 2)
                    )
            }
            .accessibilityLabel(field.title)
            .accessibilityIdentifier(field.sliderAccessibilityId ?? field.title)
            .apply { view in
                if #available(iOS 17, *) {
                    view.onKeyPress(.leftArrow) {
                        onValueChanged(max(field.value - field.step, field.range.lowerBound))
                        return .handled
                    }
                    .onKeyPress(.rightArrow) {
                        onValueChanged(min(field.value + field.step, field.range.upperBound))
                        return .handled
                    }
                } else {
                    view
                }
            }

            Text(String(Int(field.value)))
                .styleGuide(.body, monoSpacedDigit: true)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                .accessibilityIdentifier(field.sliderValueAccessibilityId ?? field.id)
                .accessibilityHidden(true)
                .frame(minWidth: 25)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .cornerRadius(10)
    }

    // MARK: Initialization

    /// Initialize a `SliderFieldView`.
    ///
    /// - Parameters:
    ///   - field: The data for displaying the field.
    ///   - onEditingChanged: A closure containing the action to take when the slider begins or ends editing.
    ///   - onValueChanged: A closure containing the action to take when a new value is selected.
    ///
    init(
        field: SliderField<State>,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onValueChanged: @escaping (Double) -> Void
    ) {
        self.field = field
        self.onEditingChanged = onEditingChanged
        self.onValueChanged = onValueChanged
    }
}
