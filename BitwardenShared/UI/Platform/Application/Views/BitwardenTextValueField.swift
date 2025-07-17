import BitwardenResources
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

    /// A flag to determine whether to use a `UITextView` implementation instead of the default SwiftUI-based text view.
    /// When `true`, a `UITextView` will be used for improved text selection and cursor/keyboard management.
    var useUIKitTextView: Bool

    /// The text value to display in this field.
    var value: String

    /// The (optional) accessibility identifier to apply to the displayed value of the field
    var valueAccessibilityIdentifier: String?

    /// Any accessory content that should be displayed on the trailing edge of the field. This
    /// content automatically has the `AccessoryButtonStyle` applied to it.
    var accessoryContent: AccessoryContent?

    /// A value indicating whether the textfield is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// A state variable that holds the dynamic height of the text view.
    /// This value is updated based on the content size of the text view,
    /// allowing for automatic resizing to fit the text content.
    /// The initial height is set to a default value of 28 points.
    @SwiftUI.State private var textViewDynamicHeight: CGFloat = 28

    // MARK: View

    var body: some View {
        BitwardenField(
            title: title,
            titleAccessibilityIdentifier: titleAccessibilityIdentifier
        ) {
            if useUIKitTextView {
                BitwardenUITextView(
                    text: .constant(value),
                    calculatedHeight: $textViewDynamicHeight,
                    isEditable: false,
                    isFocused: .constant(false)
                )
                .frame(minHeight: textViewDynamicHeight)
            } else {
                Text(value)
                    .styleGuide(.body, includeLinePadding: false, includeLineSpacing: false)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(
                        isEnabled
                            ? SharedAsset.Colors.textPrimary.swiftUIColor
                            : SharedAsset.Colors.textDisabled.swiftUIColor
                    )
                    .accessibilityIdentifier(valueAccessibilityIdentifier ?? value)
                    .if(textSelectionEnabled) { textView in
                        textView
                            .textSelection(.enabled)
                    }
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
    ///     This doesn't allow range selection, only copy/share actions.
    ///   - useUIKitTextView: Whether we should use a UITextView or a SwiftUI version.
    ///   - accessoryContent: Any accessory content that should be displayed on the trailing edge of
    ///     the field. This content automatically has the `AccessoryButtonStyle` applied to it.
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = "ItemName",
        value: String,
        valueAccessibilityIdentifier: String? = "ItemValue",
        textSelectionEnabled: Bool = true,
        useUIKitTextView: Bool = false,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.textSelectionEnabled = textSelectionEnabled
        self.title = title
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.value = value
        self.useUIKitTextView = useUIKitTextView
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
    ///     This doesn't allow range selection, only copy/share actions.
    ///   - useUIKitTextView: Whether we should use a UITextView or a SwiftUI version.
    ///
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = "ItemName",
        value: String,
        valueAccessibilityIdentifier: String? = "ItemValue",
        textSelectionEnabled: Bool = true,
        useUIKitTextView: Bool = false
    ) {
        self.init(
            title: title,
            titleAccessibilityIdentifier: titleAccessibilityIdentifier,
            value: value,
            valueAccessibilityIdentifier: valueAccessibilityIdentifier,
            textSelectionEnabled: textSelectionEnabled,
            useUIKitTextView: useUIKitTextView
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
    ///   - useUIKitTextView: Whether we should use a UITextView or a SwiftUI version.
    ///   - copyButtonAction: The action to perform when the button is pressed.
    ///   - copyButtonAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the button.
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = "ItemName",
        value: String,
        valueAccessibilityIdentifier: String? = "ItemValue",
        textSelectionEnabled: Bool = true,
        useUIKitTextView: Bool = false,
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
            useUIKitTextView: useUIKitTextView,
            accessoryContent: {
                AccessoryButton(
                    asset: Asset.Images.copy24,
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

#Preview("Legacy view") {
    VStack {
        BitwardenTextValueField(
            title: "Title",
            value: "Text field text",
            useUIKitTextView: true
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
#endif
