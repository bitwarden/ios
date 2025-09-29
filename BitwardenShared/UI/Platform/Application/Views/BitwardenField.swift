import BitwardenResources
import SwiftUI

// MARK: - BitwardenField

/// A standardized view used to wrap some content into a row of a list. This is commonly used in
/// forms.
struct BitwardenField<Content: View, AccessoryContent: View, FooterContent: View>: View {
    // MARK: Properties

    /// The (optional) title of the field.
    var title: String?

    /// The (optional) accessibility identifier to apply to the title of the field (if it exists).
    var titleAccessibilityIdentifier: String?

    /// The (optional) footer content to display underneath the field.
    var footerContent: FooterContent?

    /// The content that should be displayed in the field.
    var content: Content

    /// Any accessory content that should be displayed on the trailing edge of the field. This
    /// content automatically has the `AccessoryButtonStyle` applied to it.
    var accessoryContent: AccessoryContent?

    /// Whether the view allows user interaction.
    @Environment(\.isEnabled) var isEnabled: Bool

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contentView()

            footerView()
        }
        .padding(.leading, 16)
        .background(
            isEnabled
                ? SharedAsset.Colors.backgroundSecondary.swiftUIColor
                : SharedAsset.Colors.backgroundSecondaryDisabled.swiftUIColor
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Initialization

    /// Creates a new `BitwardenField`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists)
    ///   - content: The content that should be displayed in the field.
    ///   - accessoryContent: Any accessory content that should be displayed on the trailing edge of
    ///     the field. This content automatically has the `AccessoryButtonStyle` applied to it.
    ///   - footerContent: The (optional) footer content to display underneath the field.
    ///
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryContent: () -> AccessoryContent,
        @ViewBuilder footerContent: () -> FooterContent
    ) {
        self.title = title
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.content = content()
        self.accessoryContent = accessoryContent()
        self.footerContent = footerContent()
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
                        .foregroundColor(
                            isEnabled
                                ? SharedAsset.Colors.textSecondary.swiftUIColor
                                : SharedAsset.Colors.textDisabled.swiftUIColor
                        )
                        .accessibilityIdentifier(titleAccessibilityIdentifier ?? title)
                }

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let accessoryContent {
                HStack(spacing: 16) {
                    accessoryContent
                        .buttonStyle(.accessory)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.trailing, 16)
        .frame(minHeight: 64)
    }

    /// The view to display at the footer below the main content.
    @ViewBuilder
    private func footerView() -> some View {
        if let footerContent {
            Group {
                if let footerContent = footerContent as? Text {
                    footerContent
                        .styleGuide(.footnote, includeLinePadding: false, includeLineSpacing: false)
                        .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 12)
                } else {
                    footerContent
                }
            }
            // Apply trailing padding to the content, extend the frame the full width of view, and
            // add the divider in the background to ensure the divider is only shown if there's
            // content returned by the @ViewBuilder closure. Otherwise, an `if` block in the closure
            // that evaluates to false will have non-optional content but doesn't display anything
            // so the divider shouldn't be shown.
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .top) {
                Divider()
            }
        }
    }
}

extension BitwardenField where AccessoryContent == EmptyView {
    /// Creates a new `BitwardenField`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists)
    ///   - content: The content that should be displayed in the field.
    ///   - footer: The (optional) footer content to display underneath the field.
    ///
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer footerContent: () -> FooterContent
    ) {
        self.title = title
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.content = content()
        accessoryContent = nil
        self.footerContent = footerContent()
    }
}

extension BitwardenField where FooterContent == EmptyView {
    /// Creates a new `BitwardenField`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists)
    ///   - content: The content that should be displayed in the field.
    ///   - accessoryContent: Any accessory content that should be displayed on the trailing edge of
    ///     the field. This content automatically has the `AccessoryButtonStyle` applied to it.
    ///
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.title = title
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.content = content()
        self.accessoryContent = accessoryContent()
    }
}

extension BitwardenField where AccessoryContent == EmptyView, FooterContent == EmptyView {
    /// Creates a new `BitwardenField` without accessory content.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists)
    ///   - content: The content that should be displayed in the field.
    ///
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        footerContent = nil
        self.content = content()
        accessoryContent = nil
    }
}

extension BitwardenField where FooterContent == Text {
    /// Creates a new `BitwardenField`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists)
    ///   - footer: The (optional) footer content to display underneath the field.
    ///   - content: The content that should be displayed in the field.
    ///   - accessoryContent: Any accessory content that should be displayed on the trailing edge of
    ///     the field. This content automatically has the `AccessoryButtonStyle` applied to it.
    ///
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        footer: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.title = title
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        footerContent = Text(footer)
        self.content = content()
        self.accessoryContent = accessoryContent()
    }
}

extension BitwardenField where AccessoryContent == EmptyView, FooterContent == Text {
    /// Creates a new `BitwardenField`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - titleAccessibilityIdentifier: The (optional) accessibility identifier to apply
    ///     to the title of the field (if it exists)
    ///   - footer: The (optional) footer content to display underneath the field.
    ///   - content: The content that should be displayed in the field.
    ///
    init(
        title: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        footer: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        footerContent = Text(footer)
        self.content = content()
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    VStack {
        BitwardenField(title: "Title") {
            Text("Value")
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
        }

        BitwardenField(title: "Title", footer: "Text footer") {
            Text("Value")
        }

        BitwardenField(title: "Title") {
            Text("Value")
        } footer: {
            Button("Button footer") {}
                .buttonStyle(.bitwardenBorderless)
                .padding(.vertical, 14)
        }
    }
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
