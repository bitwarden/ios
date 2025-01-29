import SwiftUI

// MARK: - BitwardenTextView

/// A text view which allows for multiple lines of text.
///
struct BitwardenTextView: View {
    // MARK: Properties

    /// Indicates whether the `UITextView` is editable. When set to `true`, the user can edit the
    /// text. If `false`, the text view is read-only.
    let isEditable = true

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
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
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
    ///
    init(title: String? = nil, text: Binding<String>) {
        self.title = title
        _text = text
    }

    // MARK: Private

    /// The main content for the view, containing the title label and text view.
    private func contentView() -> some View {
        ZStack(alignment: showPlaceholder ? .leading : .topLeading) {
            // The placeholder and title text which is vertically centered in the view when the
            // text field doesn't have focus and is empty and otherwise displays above the text field.
            titleText(showPlaceholder: showPlaceholder)
                .accessibilityHidden(true)

            // Since the title changes font size based on if it's the placeholder, this hidden
            // view preserves space to show the title in it's placeholder form. This prevents
            // the field from changing size when the placeholder's visibility changes.
            titleText(showPlaceholder: true)
                .hidden()

            VStack(alignment: .leading, spacing: 2) {
                // This preserves space for the title to lay out above the text field when
                // it transitions from the centered to top position. But it's always hidden and
                // the text above is the one that moves during the transition.
                titleText(showPlaceholder: false)
                    .hidden()

                textView()
            }
        }
        .animation(.linear(duration: 0.1), value: isFocused)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 64)
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

    /// The title/placeholder text for the field.
    @ViewBuilder
    private func titleText(showPlaceholder: Bool) -> some View {
        if let title {
            Text(title)
                .styleGuide(
                    showPlaceholder ? .body : .subheadline,
                    weight: showPlaceholder ? .regular : .semibold,
                    includeLinePadding: false,
                    includeLineSpacing: false
                )
                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
        }
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
    .background(Asset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
