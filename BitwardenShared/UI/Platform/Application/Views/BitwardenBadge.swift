import BitwardenResources
import SwiftUI

// MARK: BitwardenBadge

/// A view that displays some text surrounded by a circular background, similar to an iOS icon badge.
///
struct BitwardenBadge: View {
    // MARK: Properties

    /// Padding applied between the text and the circular background. Scales with dynamic type)
    ///
    /// Scaling is relative to the title style so it doesn't add quite as much padding with
    /// the larger font sizes.
    @ScaledMetric(relativeTo: .title)
    var badgePadding: CGFloat = 2

    /// The value to display in the badge.
    let badgeValue: String

    /// The size of the rendered text in the badge.
    @SwiftUI.State var textSize = CGSize.zero

    // MARK: Computed Properties

    /// The diameter of the circle badge background based on the text size.
    var circleDiameter: CGFloat {
        max(textSize.width, textSize.height)
    }

    // MARK: View

    var body: some View {
        Text(badgeValue)
            .styleGuide(.callout, weight: .bold, includeLinePadding: false, includeLineSpacing: false)
            .foregroundStyle(SharedAsset.Colors.iconBadgeForeground.swiftUIColor)
            .onSizeChanged { textSize = $0 }
            // Add custom horizontal and vertical padding to ensure the frame of the badge is a
            // square. When the view is clipped to a circle, this ensures the frame of the view
            // matches the size of the circle. Otherwise, clipping can cause there to be extra
            // space in the frame which can affect the layout when the badge is used.
            .padding(.horizontal, (circleDiameter - textSize.width) / 2 + badgePadding)
            .padding(.vertical, (circleDiameter - textSize.height) / 2 + badgePadding)
            .background(SharedAsset.Colors.iconBadgeBackground.swiftUIColor)
            .clipShape(Circle())
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    BitwardenBadge(badgeValue: "3")
}
#endif
