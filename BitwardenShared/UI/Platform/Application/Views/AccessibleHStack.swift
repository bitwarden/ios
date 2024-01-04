import SwiftUI

// MARK: - AccessibleHStack

/// An `HStack` that will automatically convert to a `VStack` when the user's dynamic type settings
/// exceed the specified value.
///
struct AccessibleHStack<Content>: View where Content: View {
    // MARK: Private Properties

    /// The content to display in this stack.
    private let content: Content

    /// The current Dynamic Type size.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// A flag indicating if this stack should be using an `HStack` to layout its content
    /// horizontally.
    private var isLayoutHorizontal: Bool {
        guard let minVerticalDynamicTypeSize else { return !dynamicTypeSize.isAccessibilitySize }
        return dynamicTypeSize < minVerticalDynamicTypeSize
    }

    // MARK: Properties

    /// The guide for aligning the subviews in this stack. This guide has the same vertical (in an
    /// `HStack`) or horizontal (in a `VStack`) screen coordinate for every subview.
    let alignment: Alignment

    /// The minimum `DynamicTypeSize` for this view to layout its content vertically.
    ///
    /// Once the current `DynamicTypeSize` setting matches or exceeds this value this view's
    /// `content` will be rendered in a `VStack`. If `nil` is provided,
    /// `DynamicTypeSize.isAccessibilitySize` will be used to swap between `HStack` and `VStack`
    /// instead.
    let minVerticalDynamicTypeSize: DynamicTypeSize?

    /// The distance between adjacent subviews, or `nil` if you want the stack to choose a default
    /// distance for each pair of subviews.
    let spacing: CGFloat?

    // MARK: View

    var body: some View {
        if isLayoutHorizontal {
            HStack(alignment: alignment.vertical, spacing: spacing) {
                content
            }
        } else {
            VStack(alignment: alignment.horizontal, spacing: spacing) {
                content
            }
        }
    }

    // MARK: Initialization

    /// Creates a new `AccessibleHStack`.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack. This guide has the same
    ///     vertical (in an `HStack`) or horizontal (in a `VStack`) screen coordinate for every
    ///     subview. Defaults to `.center`, which centers content horizontally and vertically.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you want the stack to
    ///     choose a default distance for each pair of subviews. Defaults to `.nil`.
    ///   - minVerticalDynamicTypeSize: The `DynamicTypeSize` for this view to swap on. This value
    ///     should be the smallest type size that should be rendered in a `VStack`. If `nil` is
    ///     provided, `DynamicTypeSize.isAccessibilitySize` will be used to swap between `HStack`
    ///     and `VStack` instead. Defaults to `nil`.
    ///   - content: The `Content` to display in this stack.
    ///
    init(
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        minVerticalDynamicTypeSize: DynamicTypeSize? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.minVerticalDynamicTypeSize = minVerticalDynamicTypeSize
        self.content = content()
    }
}
