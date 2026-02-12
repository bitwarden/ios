import BitwardenKit
import BitwardenResources
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
    let action: () async -> Void

    // MARK: View

    var body: some View {
        AsyncButton(action: action) {
            image.imageStyle(.floatingActionButton)
        }
        .buttonStyle(CircleButtonStyle(diameter: 50))
        .accessibilitySortPriority(1)
    }
}

#if DEBUG
#Preview {
    VStack {
        FloatingActionButton(
            image: SharedAsset.Icons.pencil32.swiftUIImage,
        ) {}
    }
    .padding()
}
#endif
