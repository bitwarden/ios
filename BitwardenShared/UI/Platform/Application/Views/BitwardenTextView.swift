import BitwardenResources
import SwiftUI

// MARK: - BitwardenTextView

/// A text view which allows for multiple lines of text.
///
struct BitwardenTextView: View {
    // MARK: Properties

    /// Indicates whether the `UITextView` is editable. When set to `true`, the user can edit the
    /// text. If `false`, the text view is read-only.
    let isEditable: Bool

    /// The text entered into the text view.
    @Binding var text: String

    /// The title of the text view.
    let title: String?

    // MARK: Private Properties

    /// Whether the text view is currently focused.
    @SwiftUI.State private var isFocused = false

    /// Whether the placeholder text should be shown in the text field.
    private var showPlaceholder: Bool {
        !isFocused && text.isEmpty
    }

    /// The height of the text view.
    @SwiftUI.State private var textViewHeight: CGFloat = 28

    // MARK: View

    var body: some View {
        contentView()
            .padding(.leading, 16)
            .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                isFocused = true
            }
    }

    // MARK: Initialization

    /// Initialize a `BitwardenTextView`.
    ///
    /// - Parameters:
    ///   - title: The title of the text view.
    ///   - text: The text entered into the text view.
    ///   - isEditable: Indicates whether the text view is editable.
    ///
    init(title: String? = nil, text: Binding<String>, isEditable: Bool = true) {
        self.title = title
        _text = text
        self.isEditable = isEditable
    }

    // MARK: Private

    /// The main content for the view, containing the title label and text view.
    private func contentView() -> some View {
        BitwardenFloatingTextLabel(title: title, showPlaceholder: showPlaceholder) {
            textView()
        }
    }

    /// The text view which can contain multiple lines of text.
    private func textView() -> some View {
        BitwardenUITextView(
            text: $text,
            calculatedHeight: $textViewHeight,
            isEditable: isEditable,
            isFocused: $isFocused
        )
        .frame(minHeight: textViewHeight)
        .accessibilityLabel(title ?? "")
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack {
        BitwardenTextView(title: "Title", text: .constant(""))

        BitwardenTextView(title: "Title", text: .constant("Simple text"))

        BitwardenTextView(
            title: "Title",
            text: .constant(
                """
                Text
                that
                can
                span
                multiple
                lines.
                """
            )
        )
    }
    .fixedSize(horizontal: false, vertical: true)
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
