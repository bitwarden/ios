import BitwardenResources
import SwiftUI

// MARK: - ContentBlock

/// A view that displays a block of content, where each content item is separated by a divider.
/// The block has the secondary background color applied with rounded corners.
///
/// Adapted from: https://movingparts.io/variadic-views-in-swiftui
///
struct ContentBlock<Content: View>: View {
    // MARK: Properties

    /// The content to display in the content block.
    let content: Content

    /// The amount of leading padding to apply to the divider.
    let dividerLeadingPadding: CGFloat

    // MARK: View

    var body: some View {
        // This uses SwiftUI's `VariadicView` API, which isn't part of SwiftUI's public API but
        // since much of SwiftUI itself uses this, there's a low likelihood of this being removed.
        _VariadicView.Tree(Layout(dividerLeadingPadding: dividerLeadingPadding)) {
            content
        }
    }

    // MARK: Initialization

    /// Initialize a `ContentBlock`.
    ///
    /// - Parameters:
    ///   - dividerLeadingPadding: The amount of leading padding to apply to the divider. Defaults
    ///     to `0` which will cause the divider to span the full width of the view.
    ///   - content: The content to display in the content block.
    ///
    init(dividerLeadingPadding: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.dividerLeadingPadding = dividerLeadingPadding
    }
}

extension ContentBlock {
    /// The layout for the content block.
    private struct Layout: _VariadicView_UnaryViewRoot {
        // MARK: Properties

        /// The amount of leading padding to apply to the divider.
        let dividerLeadingPadding: CGFloat

        // MARK: View

        func body(children: _VariadicView.Children) -> some View {
            let last = children.last?.id

            VStack(spacing: 0) {
                ForEach(children) { child in
                    VStack(alignment: .leading, spacing: 0) {
                        child

                        if child.id != last {
                            Divider()
                                .padding(.leading, dividerLeadingPadding)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - View + ContentBlock

extension View {
    /// Wraps the view within a `ContentBlock`.
    ///
    func contentBlock() -> some View {
        ContentBlock {
            self
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    ContentBlock {
        Text("Apple 🍎").padding()
        Text("Banana 🍌").padding()
        Text("Grapes 🍇").padding()
    }
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
