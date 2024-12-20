import SwiftUI

// MARK: - BitwardenField

/// A standardized view used to wrap some content into a row of a list. This is commonly used in
/// forms.
struct BitwardenField<Content, AccessoryContent>: View where Content: View, AccessoryContent: View {
    // MARK: Properties

    /// The (optional) title of the field.
    var title: String?

    /// The (optional) accessibility identifier to apply to the title of the field (if it exists).
    var titleAccessibilityIdentifier: String?

    /// The (optional) footer to display underneath the field.
    var footer: String?

    /// The (optional) accessibility identifier to apply to the footer of the field (if it exists).
    var footerAccessibilityIdentifier: String?

    /// The vertical padding to apply around `content`. Defaults to `8`.
    var verticalPadding: CGFloat

    /// The content that should be displayed in the field.
    var content: Content

    /// Any accessory content that should be displayed on the trailing edge of the field. This
    /// content automatically has the `AccessoryButtonStyle` applied to it.
    var accessoryContent: AccessoryContent?

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contentView()

            footerView()
        }
        .padding(.horizontal, 16)
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Initialization

    /// Creates a new `BitwardenField`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists)
    ///   - footer: The (optional) footer to display underneath the field.
    ///   - footerAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the footer of the field (if it exists)
    ///   - verticalPadding: The vertical padding to apply around `content`. Defaults to `8`.
    ///   - content: The content that should be displayed in the field.
    ///   - accessoryContent: Any accessory content that should be displayed on the trailing edge of
    ///     the field. This content automatically has the `AccessoryButtonStyle` applied to it.
    ///
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        footer: String? = nil,
        footerAccessibilityIdentifier: String? = nil,
        verticalPadding: CGFloat = 8,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.title = title
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.footer = footer
        self.footerAccessibilityIdentifier = footerAccessibilityIdentifier
        self.verticalPadding = verticalPadding
        self.content = content()
        self.accessoryContent = accessoryContent()
    }

    // MARK: Private

    /// The main content for the view, containing the title and value.
    @ViewBuilder
    private func contentView() -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                if let title {
                    Text(title)
                        .styleGuide(
                            .subheadline,
                            weight: .semibold,
                            includeLinePadding: false,
                            includeLineSpacing: false
                        )
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        .accessibilityIdentifier(titleAccessibilityIdentifier ?? title)
                }

                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let accessoryContent {
                HStack(spacing: 16) {
                    accessoryContent
                        .buttonStyle(.accessory)
                }
            }
        }
        .padding(.vertical, 12)
        .frame(minHeight: 64)
    }

    /// The view to display at the footer below the main content.
    @ViewBuilder
    private func footerView() -> some View {
        if let footer {
            VStack(alignment: .leading, spacing: 0) {
                Divider()

                Text(footer)
                    .styleGuide(.footnote, includeLinePadding: false, includeLineSpacing: false)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .accessibilityIdentifier(footerAccessibilityIdentifier ?? footer)
                    .padding(.vertical, 12)
            }
        }
    }
}

extension BitwardenField where AccessoryContent == EmptyView {
    /// Creates a new `BitwardenField` without accessory content.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists)
    ///   - footer: The (optional) footer to display underneath the field.
    ///   - footerAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the footer of the field (if it exists)
    ///   - verticalPadding: The vertical padding to apply around `content`. Defaults to `8`.
    ///   - content: The content that should be displayed in the field.
    ///
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        footer: String? = nil,
        footerAccessibilityIdentifier: String? = nil,
        verticalPadding: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.footer = footer
        self.footerAccessibilityIdentifier = footerAccessibilityIdentifier
        self.verticalPadding = verticalPadding
        self.content = content()
        accessoryContent = nil
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    VStack {
        BitwardenField(title: "Title") {
            Text("Value")
                .styleGuide(.body)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        }

        BitwardenField(title: "Title", footer: "Footer") {
            Text("Value")
        }
    }
    .padding()
    .background(Asset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
