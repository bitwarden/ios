import SwiftUI

// MARK: - FloatingActionButton

/// A view representing a floating action button for adding new items.
///
struct FloatingActionButton: View {
    // MARK: Properties

    /// The bottom content offset padding around the floating action button.
    /// This is the button size plus the bottom/top padding (50 + 16).
    static let bottomOffsetPadding: CGFloat = 66

    /// The image to be displayed within the button.
    let image: Image

    /// A closure that defines the action to be performed when the button is tapped.
    let action: () -> Void

    // MARK: View

    var body: some View {
        Button(action: action) {
            image
                .imageStyle(
                    .init(
                        color: Asset.Colors.buttonFilledForeground.swiftUIColor,
                        scaleWithFont: false,
                        width: 24,
                        height: 24
                    )
                )
        }
        .buttonStyle(CircleButtonStyle())
    }
}

#if DEBUG
#Preview {
    VStack {
        FloatingActionButton(
            image: Asset.Images.pencil.swiftUIImage) {}
    }
    .padding()
}
#endif
