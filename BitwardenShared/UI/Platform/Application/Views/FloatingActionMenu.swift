import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - FloatingActionMenu

/// A view representing a floating action button which displays a menu when tapped. This is visually
/// identical to `FloatingActionButton` but allows for a `Menu` to be displayed when tapped.
///
struct FloatingActionMenu<Content: View>: View {
    // MARK: Properties

    /// The content to display in the context menu.
    let content: Content

    /// The image to display within the button.
    let image: Image

    // MARK: View

    var body: some View {
        Menu {
            content
        } label: {
            image.imageStyle(.floatingActionButton)
        }
        .accessibilitySortPriority(1)
        .apply { view in
            if #available(iOS 17, *) {
                view.buttonStyle(CircleButtonStyle(diameter: 50))
            } else {
                // Prior to iOS 17, applying a custom button style to a Menu component has no effect,
                // so a custom menu style is needed instead.
                view.menuStyle(CircleMenuStyle(diameter: 50))
            }
        }
    }

    // MARK: Initialization

    /// Initialize a `FloatingActionMenu`.
    ///
    /// - Parameters:
    ///   - image: The image to display within the button.
    ///   - content: The content to display in the context menu.
    ///
    init(image: Image, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.image = image
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack {
        FloatingActionMenu(image: SharedAsset.Icons.plus32.swiftUIImage) {
            Button("Item 1") {}
            Button("Item 2") {}
            Button("Item 3") {}

            Divider()

            Button("Other Item") {}
        }
    }
    .padding()
}
#endif
