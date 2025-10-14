import BitwardenResources
import SwiftUI

// MARK: - SliderField

/// The data necessary for displaying a `SliderFieldView`.
///
public struct SliderField<State>: Equatable, Identifiable {
    // MARK: Properties

    /// A key path for updating the backing value for the slider field.
    public let keyPath: WritableKeyPath<State, Double>

    /// The range of allowable values for the slider.
    public let range: ClosedRange<Double>

    /// The accessibility id for the slider. The `title` will be used as the accessibility id
    /// if this is `nil`.
    let sliderAccessibilityId: String?

    /// The accessibility id for the slider value. The `id` will be used as the accessibility id
    /// if this is `nil`.
    let sliderValueAccessibilityId: String?

    /// The distance between each valid value.
    public let step: Double

    /// The title of the field.
    public let title: String

    /// The current slider value.
    public let value: Double

    // MARK: Identifiable

    public var id: String {
        "SliderField-\(title)"
    }

    // MARK: Initializer

    /// Initializes a `SliderField`.
    ///
    /// - Parameters:
    ///   - keyPath: A key path for updating the backing value for the slider field.
    ///   - range: The range of allowable values for the slider.
    ///   - sliderAccessibilityId: The accessibility ID for the slider.
    ///     The `title` will be used as the accessibility ID if this is `nil`.
    ///   - sliderValueAccessibilityId: The accessibility ID for the slider value.
    ///     The `id` will be used as the accessibility ID if this is `nil`.
    ///   - step: The distance between each valid value.
    ///   - title: The title of the field.
    ///   - value: The current slider value.
    public init(
        keyPath: WritableKeyPath<State, Double>,
        range: ClosedRange<Double>,
        sliderAccessibilityId: String?,
        sliderValueAccessibilityId: String?,
        step: Double,
        title: String,
        value: Double,
    ) {
        self.keyPath = keyPath
        self.range = range
        self.sliderAccessibilityId = sliderAccessibilityId
        self.sliderValueAccessibilityId = sliderValueAccessibilityId
        self.step = step
        self.title = title
        self.value = value
    }
}

// MARK: - SliderFieldView

/// A view that displays a slider for display in a form.
///
public struct SliderFieldView<State>: View {
    // MARK: Properties

    /// The data for displaying the field.
    let field: SliderField<State>

    /// A closure containing the action to take when the slider begins or ends editing.
    let onEditingChanged: @Sendable (Bool) -> Void

    /// A closure containing the action to take when a new value is selected.
    let onValueChanged: @Sendable (Double) -> Void

    /// The width of the three digit text "000" based on the current font.
    @SwiftUI.State private var minTextWidth: CGFloat = 14

    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(field.title)
                .styleGuide(.body)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .accessibilityHidden(true)

            BitwardenSlider(
                value: Binding(get: { field.value }, set: onValueChanged),
                in: field.range,
                step: field.step,
                onEditingChanged: onEditingChanged,
            )
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
                .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                .accessibilityIdentifier(field.sliderValueAccessibilityId ?? field.id)
                .accessibilityHidden(true)
                .frame(minWidth: minTextWidth)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            calculateMinTextWidth()
        }
    }

    // MARK: Initialization

    /// Initialize a `SliderFieldView`.
    ///
    /// - Parameters:
    ///   - field: The data for displaying the field.
    ///   - onEditingChanged: A closure containing the action to take when the slider begins or ends editing.
    ///   - onValueChanged: A closure containing the action to take when a new value is selected.
    ///
    public init(
        field: SliderField<State>,
        onEditingChanged: @Sendable @escaping (Bool) -> Void = { _ in },
        onValueChanged: @Sendable @escaping (Double) -> Void,
    ) {
        self.field = field
        self.onEditingChanged = onEditingChanged
        self.onValueChanged = onValueChanged
    }

    // MARK: Private methods

    /// Calculate the width of the text "000" based on the current font.
    private func calculateMinTextWidth() -> some View {
        Text("000")
            .styleGuide(.body, monoSpacedDigit: true)
            .hidden()
            .background(GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        minTextWidth = geometry.size.width
                    }
            })
    }
}
