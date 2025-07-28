import BitwardenResources
import SwiftUI

// MARK: - BitwardenStepper

/// A custom stepper component which performs increment and decrement actions.
///
struct BitwardenStepper<Label: View, Footer: View>: View {
    // MARK: Properties

    /// Whether a text field can be used to type in the value as an alternative to using the
    /// stepper buttons.
    let allowTextFieldInput: Bool

    /// An optional footer to display below the stepper.
    let footer: Footer?

    /// The label to display for the stepper.
    let label: Label

    /// The range that describes the upper and lower bounds allowed by the stepper.
    let range: ClosedRange<Int>

    /// An accessibility identifier for the text field.
    let textFieldAccessibilityIdentifier: String?

    /// The current value of the stepper.
    @Binding var value: Int

    // MARK: Private Properties

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// A state variable to track whether the text field is focused.
    @FocusState private var isTextFieldFocused: Bool

    /// The size of the stepper view.
    @SwiftUI.State private var viewSize = CGSize.zero

    // MARK: Computed Properties

    /// Returns a fixed width for the value label. This prevents the buttons from changing positions
    /// as the frame of the value changes due to variable widths for each digit's font.
    var valueWidth: CGFloat {
        // Create a string that contains a zero for each digit in the current value of the stepper
        // (e.g. if the stepper's value is 10, use "00"). "0" is used since it's the widest integer
        // value, so determining the size of the zero string gives the maximum possible width of
        // the value label for the current number of digits.
        //
        // This width will change as the number of digits changes (e.g. "9" to "10"), but that's
        // better than it changing for each digit (e.g. "0" to "1").
        let zeroString = String(repeating: "0", count: value.numberOfDigits)
        let font = FontFamily.DMSans.semiBold.font(size: StyleGuideFont.body.size)
        let traitCollection = UITraitCollection(
            preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize)
        )
        let scaledFont = UIFontMetrics.default.scaledFont(for: font, compatibleWith: traitCollection)
        let idealTextSize = (zeroString as NSString).size(withAttributes: [.font: scaledFont])

        // Use a max width to prevent the value's frame from exceeding the parent's. Subtracting off
        // 150 ensures there's some minimum room for the stepper buttons and label.
        let maxWidth = max(viewSize.width - 150, 0)
        return min(idealTextSize.width, maxWidth)
    }

    // MARK: View

    var body: some View {
        VStack(spacing: 0) {
            contentView()

            footerView()
        }
    }

    // MARK: Initialization

    /// Initialize a `BitwardenStepper`.
    ///
    /// - Parameters:
    ///   - value: The current value of the stepper.
    ///   - range: The range that describes the upper and lower bounds allowed by the stepper.
    ///   - allowTextFieldInput: Whether a text field can be used to type in the value as an
    ///     alternative to using the stepper buttons.
    ///   - textFieldAccessibilityIdentifier: An accessibility identifier for the text field.
    ///   - label: The label to display for the stepper.
    ///   - footer: A footer to display below the stepper.
    ///
    init(
        value: Binding<Int>,
        in range: ClosedRange<Int>,
        allowTextFieldInput: Bool = false,
        textFieldAccessibilityIdentifier: String? = nil,
        @ViewBuilder label: () -> Label,
        @ViewBuilder footer: () -> Footer
    ) {
        self.allowTextFieldInput = allowTextFieldInput
        self.footer = footer()
        self.label = label()
        self.range = range
        self.textFieldAccessibilityIdentifier = textFieldAccessibilityIdentifier
        _value = value
    }

    /// Initialize a `BitwardenStepper`.
    ///
    /// - Parameters:
    ///   - value: The current value of the stepper.
    ///   - range: The range that describes the upper and lower bounds allowed by the stepper.
    ///   - allowTextFieldInput: Whether a text field can be used to type in the value as an
    ///     alternative to using the stepper buttons.
    ///   - textFieldAccessibilityIdentifier: An accessibility identifier for the text field.
    ///   - label: The label to display for the stepper.
    ///
    init(
        value: Binding<Int>,
        in range: ClosedRange<Int>,
        allowTextFieldInput: Bool = false,
        textFieldAccessibilityIdentifier: String? = nil,
        @ViewBuilder label: () -> Label
    ) where Footer == EmptyView {
        self.allowTextFieldInput = allowTextFieldInput
        footer = nil
        self.label = label()
        self.range = range
        self.textFieldAccessibilityIdentifier = textFieldAccessibilityIdentifier
        _value = value
    }

    // MARK: Private

    /// The main content of the view displaying the stepper and its label.
    @ViewBuilder
    private func contentView() -> some View {
        HStack(spacing: 12) {
            label
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                value -= 1
            } label: {
                Asset.Images.minus16.swiftUIImage
            }
            .buttonStyle(CircleButtonStyle(diameter: 30))
            .disabled(value <= range.lowerBound)
            .id("decrement") // Used for ViewInspector.

            Group {
                if allowTextFieldInput {
                    textField()
                } else {
                    Text(String(value))
                        .styleGuide(.body, weight: .semibold)
                        .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                }
            }
            .frame(width: valueWidth)

            Button {
                value += 1
            } label: {
                Asset.Images.plus16.swiftUIImage
            }
            .buttonStyle(CircleButtonStyle(diameter: 30))
            .disabled(value >= range.upperBound)
            .id("increment") // Used for ViewInspector.
        }
        .onSizeChanged { size in
            viewSize = size
        }
        .accessibilityRepresentation {
            Stepper(value: $value, in: range) {
                label
            }
        }
        .padding(16)
    }

    /// An optional footer which is displayed with a divider below the stepper content.
    @ViewBuilder
    private func footerView() -> some View {
        if let footer {
            Divider()
                .padding(.leading, 16)

            footer
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    /// A text field which can be used to change the value of the stepper, as an alternative to the
    /// increment and decrement buttons.
    private func textField() -> some View {
        TextField(
            "",
            text: Binding(
                get: { String(value) },
                set: { newValue in
                    guard let intValue = Int(newValue) else { return }
                    value = intValue
                }
            )
        )
        .focused($isTextFieldFocused)
        .keyboardType(.numberPad)
        .styleGuide(.bodySemibold)
        .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
        .multilineTextAlignment(.center)
        .textFieldStyle(.plain)
        .accessibilityIdentifier(textFieldAccessibilityIdentifier ?? "")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(Localizations.save) {
                    isTextFieldFocused = false
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview {
    @Previewable @SwiftUI.State var value = 1

    VStack {
        BitwardenStepper(value: $value, in: 1 ... 4) {
            Text("Value")
        }

        BitwardenStepper(value: $value, in: 1 ... 4) {
            Text("Value")
        } footer: {
            Text("Footer")
        }
    }
    .padding()
}
#endif
