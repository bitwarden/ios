import SwiftUI

// MARK: - BitwardenMultilineTextField

/// A variant of the standard text field used within this application that allows for multiple lines
/// of text displayed vertically.
///
/// - Note: iOS 15 uses a `TextEditor` instead of `TextField` to render the text. See
///   `UI.applyDefaultAppearances()` for iOS 15 specific styling.
///
struct BitwardenMultilineTextField: View {
    // MARK: Properties

    /// The title of the text field.
    let title: String?

    /// The footer text displayed below the text field.
    let footer: String?

    /// The text entered into the text field.
    @Binding var text: String

    // MARK: View

    var body: some View {
        BitwardenField(
            title: title,
            footer: footer
        ) {
            if #available(iOSApplicationExtension 16, *) {
                TextField(
                    "",
                    text: $text,
                    axis: .vertical
                )
                .styleGuide(.body, includeLineSpacing: false)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
                .scrollDisabled(true)
            } else {
                TextEditor(
                    text: $text
                )
                .styleGuide(.body, includeLineSpacing: false)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
            }
        }
    }

    // MARK: Initialization

    /// Initializes a new `BitwardenMultilineTextField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - text: The text entered into the text field.
    ///   - footer: The footer text displayed below the text field.
    ///
    init(
        title: String?,
        text: Binding<String>,
        footer: String?
    ) {
        self.title = title
        self.footer = footer
        _text = text
    }
}
