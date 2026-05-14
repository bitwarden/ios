import BitwardenResources
import SwiftUI

// MARK: - PillBadgeStyle

/// The visual style of a `PillBadgeView`, determining the color scheme.
///
public enum PillBadgeStyle {
    /// A danger style with red colors.
    case danger

    /// A success style with green colors.
    case success

    /// A warning style with orange colors.
    case warning

    /// The background color for the pill badge.
    public var backgroundColor: Color {
        switch self {
        case .danger:
            SharedAsset.Colors.badgeDangerBackground.swiftUIColor
        case .success:
            SharedAsset.Colors.badgeSuccessBackground.swiftUIColor
        case .warning:
            SharedAsset.Colors.badgeWarningBackground.swiftUIColor
        }
    }

    /// The border color for the pill badge.
    public var borderColor: Color {
        switch self {
        case .danger:
            SharedAsset.Colors.badgeDangerBorder.swiftUIColor
        case .success:
            SharedAsset.Colors.badgeSuccessBorder.swiftUIColor
        case .warning:
            SharedAsset.Colors.badgeWarningBorder.swiftUIColor
        }
    }

    /// The text color for the pill badge.
    public var textColor: Color {
        switch self {
        case .danger:
            SharedAsset.Colors.badgeDangerText.swiftUIColor
        case .success:
            SharedAsset.Colors.badgeSuccessText.swiftUIColor
        case .warning:
            SharedAsset.Colors.badgeWarningText.swiftUIColor
        }
    }
}

// MARK: - PillBadgeView

/// A reusable pill-shaped badge view that displays a text label with a colored background,
/// text, and border based on the specified style.
///
public struct PillBadgeView: View {
    // MARK: Properties

    /// The text to display in the pill badge.
    let text: String

    /// The visual style of the pill badge.
    let style: PillBadgeStyle

    // MARK: View

    public var body: some View {
        Text(text)
            .styleGuide(
                .subheadlineSemibold,
                weight: .bold,
                includeLinePadding: false,
                includeLineSpacing: false,
            )
            .foregroundColor(style.textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(style.backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(style.borderColor, lineWidth: 1),
            )
    }

    // MARK: Initialization

    /// Initializes a `PillBadgeView`.
    ///
    /// - Parameters:
    ///   - text: The text to display in the pill badge.
    ///   - style: The visual style of the pill badge.
    ///
    public init(text: String, style: PillBadgeStyle) {
        self.text = text
        self.style = style
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        PillBadgeView(text: "Active", style: .success)
        PillBadgeView(text: "Canceled", style: .danger)
        PillBadgeView(text: "Past due", style: .warning)
        PillBadgeView(text: "Update payment", style: .warning)
    }
    .padding()
}
#endif
