import BitwardenResources
import SwiftUI

// MARK: - BitwardenFloatingTextLabel

/// A component for displaying a floating text label for a text input field. The text label can
/// display as a placeholder centered over the input field until the field either has focus or
/// contains a value. At that point, the text label will float up above the input field. This is
/// primarily meant to wrap a text field or view.
///
struct BitwardenFloatingTextLabel<Content: View, TrailingContent: View>: View {
    // MARK: Properties

    /// The primary content containing the text input field for the label.
    let content: Content

    /// A value indicating whether the text label is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// If the text field in the `Content` was disabled.
    let isTextFieldDisabled: Bool

    /// The title of the field.
    let title: String?

    /// Whether the title text should display as a placeholder centered over the field.
    let showPlaceholder: Bool

    /// Optional trailing content to display on the trailing edge of the label and text input field.
    let trailingContent: TrailingContent?

    // MARK: View

    var body: some View {
        HStack(spacing: 8) {
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

                    content
                }
            }

            trailingContent
        }
        .animation(.linear(duration: 0.1), value: showPlaceholder)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 64)
    }

    // MARK: Initialization

    /// Initialize a `BitwardenFloatingTextLabel`.
    ///
    /// - Parameters:
    ///   - title: The title of the field.
    ///   - isTextFieldDisabled: If the text field in the `Content` was disabled.
    ///   - showPlaceholder: Whether the title text should display as a placeholder centered over
    ///     the field.
    ///   - content: The primary content containing the text input field for the label.
    ///   - trailingContent: Optional trailing content to display on the trailing edge of the label
    ///     and text input field.
    ///
    init(
        title: String?,
        isTextFieldDisabled: Bool = false,
        showPlaceholder: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.content = content()
        self.isTextFieldDisabled = isTextFieldDisabled
        self.showPlaceholder = showPlaceholder
        self.title = title
        self.trailingContent = trailingContent()
    }

    /// Initialize a `BitwardenFloatingTextLabel`.
    ///
    /// - Parameters:
    ///   - title: The title of the field.
    ///   - isTextFieldDisabled: If the text field in the `Content` was disabled.
    ///   - showPlaceholder: Whether the title text should display as a placeholder centered over
    ///     the field.
    ///   - content: The primary content containing the text input field for the label.
    ///
    init(
        title: String?,
        isTextFieldDisabled: Bool = false,
        showPlaceholder: Bool,
        @ViewBuilder content: () -> Content
    ) where TrailingContent == EmptyView {
        self.content = content()
        self.isTextFieldDisabled = isTextFieldDisabled
        self.showPlaceholder = showPlaceholder
        self.title = title
        trailingContent = nil
    }

    // MARK: Private

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
                .foregroundStyle(
                    isEnabled && !isTextFieldDisabled
                        ? SharedAsset.Colors.textSecondary.swiftUIColor
                        : SharedAsset.Colors.textDisabled.swiftUIColor
                )
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack {
        BitwardenFloatingTextLabel(title: "Title", showPlaceholder: true) {
            TextField("", text: .constant(""))
        }

        BitwardenFloatingTextLabel(title: "Title", showPlaceholder: false) {
            TextField("", text: .constant("Value"))
        }

        BitwardenFloatingTextLabel(title: "Title", showPlaceholder: false) {
            TextField("", text: .constant("Value"))
        } trailingContent: {
            Asset.Images.cog24.swiftUIImage
                .foregroundStyle(SharedAsset.Colors.iconPrimary.swiftUIColor)
        }
    }
    .padding()
}
#endif
