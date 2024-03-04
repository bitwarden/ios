import SwiftUI

/// A standardized view used to display some text into a row of a list. This is commonly used in
/// forms.
struct BitwardenTextValueField<AccessoryContent>: View where AccessoryContent: View {
    // MARK: Properties

    /// The (optional) title of the field.
    var title: String?

    /// The text value to display in this field.
    var value: String

    /// Any accessory content that should be displayed on the trailing edge of the field. This
    /// content automatically has the `AccessoryButtonStyle` applied to it.
    var accessoryContent: AccessoryContent?

    // MARK: View

    var body: some View {
        BitwardenField(title: title) {
            Text(value)
                .styleGuide(.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
        } accessoryContent: {
            accessoryContent
        }
    }

    // MARK: Initialization

    /// Creates a new `BitwardenTextValueField`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - value: The text value to display in this field.
    ///   - accessoryContent: Any accessory content that should be displayed on the trailing edge of
    ///     the field. This content automatically has the `AccessoryButtonStyle` applied to it.
    ///
    init(
        title: String? = nil,
        value: String,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.title = title
        self.value = value
        self.accessoryContent = accessoryContent()
    }
}

extension BitwardenTextValueField where AccessoryContent == EmptyView {
    /// Creates a new `BitwardenTextValueField` without accessory content.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - value: The text value to display in this field.
    ///
    init(
        title: String? = nil,
        value: String
    ) {
        self.init(
            title: title,
            value: value
        ) {
            EmptyView()
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    VStack {
        BitwardenTextValueField(
            title: "Title",
            value: "Text field text"
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .previewDisplayName("No buttons")
}
#endif
