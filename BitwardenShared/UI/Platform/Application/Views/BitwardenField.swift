import SwiftUI

// MARK: - BitwardenField

/// A standardized view used to wrap some content into a row of a list. This is commonly used in
/// forms.
struct BitwardenField<Content, AccessoryContent>: View where Content: View, AccessoryContent: View {
    /// The (optional) title of the field.
    var title: String?

    /// The (optional) footer to display underneath the field.
    var footer: String?

    /// The vertical padding to apply around `content`. Defaults to `12`.
    var verticalPadding: CGFloat

    /// The content that should be displayed in the field.
    var content: Content

    /// Any accessory content that should be displayed on the trailing edge of the field. This
    /// content automatically has the `AccessoryButtonStyle` applied to it.
    var accessoryContent: AccessoryContent?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                if let title {
                    Text(title)
                        .font(.styleGuide(.subheadline))
                        .bold()
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                }

                HStack(spacing: 8) {
                    content
                        .padding(.horizontal, 16)
                        .padding(.vertical, verticalPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if let accessoryContent {
                        accessoryContent
                            .buttonStyle(.accessory)
                    }
                }
            }

            if let footer {
                Text(footer)
                    .font(.styleGuide(.footnote))
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
            }
        }
    }

    // MARK: Initialization

    /// Creates a new `BitwardenField`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - footer: The (optional) footer to display underneath the field.
    ///   - verticalPadding: The vertical padding to apply around `content`. Defaults to `12`.
    ///   - content: The content that should be displayed in the field.
    ///   - accessoryContent: Any accessory content that should be displayed on the trailing edge of
    ///     the field. This content automatically has the `AccessoryButtonStyle` applied to it.
    ///
    init(
        title: String? = nil,
        footer: String? = nil,
        verticalPadding: CGFloat = 12,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.title = title
        self.footer = footer
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
    ///   - footer: The (optional) footer to display underneath the field.
    ///   - verticalPadding: The vertical padding to apply around `content`. Defaults to `12`.
    ///   - content: The content that should be displayed in the field.
    ///
    init(
        title: String? = nil,
        footer: String? = nil,
        verticalPadding: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.verticalPadding = verticalPadding
        self.content = content()
        accessoryContent = nil
    }
}
