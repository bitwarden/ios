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
    var badgePadding: CGFloat = 8

    /// The value to display in the badge.
    let badgeValue: String

    // MARK: View

    var body: some View {
        Text(badgeValue)
            .styleGuide(.callout, weight: .bold, includeLineSpacing: false)
            .foregroundStyle(Asset.Colors.iconBadgeForeground.swiftUIColor)
            .padding(badgePadding)
            .background(Asset.Colors.iconBadgeBackground.swiftUIColor)
            .clipShape(Circle())
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    BitwardenBadge(badgeValue: "3")
}
#endif
