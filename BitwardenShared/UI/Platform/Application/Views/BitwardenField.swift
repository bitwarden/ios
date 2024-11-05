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

    /// The (optional) accessibility identifier to apply to the fooder of the field (if it exists).
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
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .styleGuide(.subheadline, weight: .semibold)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .accessibilityIdentifier(titleAccessibilityIdentifier ?? title)
            }

            HStack(spacing: 8) {
                content
                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, verticalPadding)
                    .background(Asset.Colors.backgroundSecondary.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if let accessoryContent {
                    accessoryContent
                        .buttonStyle(.accessory)
                }
            }

            if let footer {
                Text(footer)
                    .styleGuide(.footnote)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .accessibilityIdentifier(footerAccessibilityIdentifier ?? footer)
            }
        }
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
    ///     to the fooder of the field (if it exists)
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
    ///     to the fooder of the field (if it exists)
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
