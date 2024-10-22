import SwiftUI

/// A standardized view used to display some text into a row of a list. This is commonly used in
/// forms.
struct BitwardenTextValueField<AccessoryContent>: View where AccessoryContent: View {
    // MARK: Properties

    /// Whether the text selection is enabled.
    /// Warning: This only allows Copy/Share actions but not range selection.
    var textSelectionEnabled: Bool

    /// The (optional) title of the field.
    var title: String?

    /// The (optional) accessibility identifier to apply to the title of the field (if it exists)
    var titleAccessibilityIdentifier: String?

    /// The text value to display in this field.
    var value: String

    /// The (optional) accessibility identifier to apply to the displayed value of the field
    var valueAccessibilityIdentifier: String?

    /// Any accessory content that should be displayed on the trailing edge of the field. This
    /// content automatically has the `AccessoryButtonStyle` applied to it.
    var accessoryContent: AccessoryContent?

    // MARK: View

    var body: some View {
        BitwardenField(title: title, titleAccessibilityIdentifier: titleAccessibilityIdentifier) {
            Text(value)
                .styleGuide(.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .accessibilityIdentifier(valueAccessibilityIdentifier ?? value)
                .if(textSelectionEnabled) { textView in
                    textView
                        .textSelection(.enabled)
                }
        } accessoryContent: {
            accessoryContent
        }
    }

    // MARK: Initialization

    /// Creates a new `BitwardenTextValueField`.
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists)
    ///   - value: The text value to display in this field.
    ///   - valueAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the displayed value of the field
    ///   - textSelectionEnabled: Whether text selection is enabled.
    ///   This doesn't allow range selection, only copy/share actions.
    ///   - accessoryContent: Any accessory content that should be displayed on the trailing edge of
    ///     the field. This content automatically has the `AccessoryButtonStyle` applied to it.
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = "ItemName",
        value: String,
        valueAccessibilityIdentifier: String? = "ItemValue",
        textSelectionEnabled: Bool = true,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.textSelectionEnabled = textSelectionEnabled
        self.title = title
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.value = value
        self.valueAccessibilityIdentifier = valueAccessibilityIdentifier
        self.accessoryContent = accessoryContent()
    }
}

extension BitwardenTextValueField where AccessoryContent == EmptyView {
    /// Creates a new `BitwardenTextValueField` without accessory content.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists)
    ///   - value: The text value to display in this field.
    ///   - valueAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the displayed value of the field
    ///   - textSelectionEnabled: Whether text selection is enabled.
    ///   This doesn't allow range selection, only copy/share actions.
    ///
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = "ItemName",
        value: String,
        valueAccessibilityIdentifier: String? = "ItemValue",
        textSelectionEnabled: Bool = true
    ) {
        self.init(
            title: title,
            titleAccessibilityIdentifier: titleAccessibilityIdentifier,
            value: value,
            valueAccessibilityIdentifier: valueAccessibilityIdentifier,
            textSelectionEnabled: textSelectionEnabled
        ) {
            EmptyView()
        }
    }
}

extension BitwardenTextValueField where AccessoryContent == AccessoryButton {
    /// Creates a new `BitwardenTextValueField` with a button as accessory content.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists).
    ///   - value: The text value to display in this field.
    ///   - valueAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the displayed value of the field.
    ///   - textSelectionEnabled: Whether text selection is enabled.
    ///   - copyButtonAction: The action to perform when the button is pressed.
    ///   - buttonAccessibilityLabel: The (optional) accessibility label to apply to the button.
    ///   - copyButtonAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the button.
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = "ItemName",
        value: String,
        valueAccessibilityIdentifier: String? = "ItemValue",
        textSelectionEnabled: Bool = true,
        copyButtonAccessibilityIdentifier: String,
        copyButtonAction: @escaping () -> Void
    ) {
        // Initialize the BitwardenTextValueField with the button as the accessory content
        self.init(
            title: title,
            titleAccessibilityIdentifier: titleAccessibilityIdentifier,
            value: value,
            valueAccessibilityIdentifier: valueAccessibilityIdentifier,
            textSelectionEnabled: textSelectionEnabled,
            accessoryContent: {
                AccessoryButton(
                    asset: Asset.Images.copy,
                    accessibilityLabel: Localizations.copy,
                    accessibilityIdentifier: copyButtonAccessibilityIdentifier,
                    action: copyButtonAction
                )
            }
        )
    }
}

// MARK: Previews

#if DEBUG
#Preview("No buttons") {
    VStack {
        BitwardenTextValueField(
            title: "Title",
            value: "Text field text"
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
#endif
