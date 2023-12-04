import SwiftUI

// MARK: - BitwardenField

/// A standardized view used to wrap some content into a row of a list. This is commonly used in
/// forms.
struct BitwardenField<Content, AccessoryContent>: View where Content: View, AccessoryContent: View {
    /// The (optional) title of the field.
    var title: String?

    /// The content that should be displayed in the field.
    var content: Content

    /// Any accessory content that should be displayed on the trailing edge of the field. This
    /// content automatically has the `AccessoryButtonStyle` applied to it.
    var accessoryContent: AccessoryContent?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.styleGuide(.subheadline))
                    .bold()
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .lineSpacing(5.0)
                    .minSize(minHeight: 20)
            }

            HStack(spacing: 8) {
                ZStack {
                    Spacer()
                    content
                }
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if let accessoryContent {
                    accessoryContent
                        .buttonStyle(.accessory)
                }
            }
        }
    }

    // MARK: Initialization

    /// Creates a new `BitwardenField`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - content: The content that should be displayed in the field.
    ///   - accessoryContent: Any accessory content that should be displayed on the trailing edge of
    ///     the field. This content automatically has the `AccessoryButtonStyle` applied to it.
    ///
    init(
        title: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.title = title
        self.content = content()
        self.accessoryContent = accessoryContent()
    }
}

extension BitwardenField where AccessoryContent == EmptyView {
    /// Creates a new `BitwardenField` without accessory content.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - content: The content that should be displayed in the field.
    ///
    init(
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
        accessoryContent = nil
    }
}

/// A view modifier to add minimum size to a view
struct MinimumSizeModifier: ViewModifier {
    /// The alignment of the view in a ZStack.
    let alignment: Alignment

    /// The minimum width of the ZStack.
    let minWidth: CGFloat

    /// The minimum height of the ZStack.
    let minHeight: CGFloat

    func body(content: Content) -> some View {
        ZStack(alignment: alignment) {
            Spacer()
                .frame(width: minWidth, height: minHeight)
            content
        }
        .frame(minWidth: minWidth, minHeight: minHeight)
    }
}

/// An extension to simplify adding minimum sizes.
extension View {
    /// Wraps the view in a ZStack set to a minimum height.
    ///
    /// - Parameters:
    ///    - minWidth: The minimum width of the ZStack.
    ///    - minHeight: The minimum height of the ZStack.
    ///    - alignment: The alignment of the view in a ZStack.
    /// - Returns: The view wrapped in a ZStack.
    func minSize(minWidth: CGFloat = 0.0, minHeight: CGFloat = 0.0, alignment: Alignment = .topLeading) -> some View {
        modifier(
            MinimumSizeModifier(
                alignment: alignment,
                minWidth: minWidth,
                minHeight: minHeight
            )
        )
    }
}
