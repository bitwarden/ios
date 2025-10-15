import Foundation

// MARK: - ButtonStyleSize

/// The different size buttons which can be supported by button styles.
///
public enum ButtonStyleSize {
    /// A small button, with subheadline-sized text.
    case small

    /// A medium-sized button, with callout-sized text.
    case medium

    /// A large button, with body-sized text.
    case large

    /// The font style of the button label for this size.
    var fontStyle: StyleGuideFont {
        switch self {
        case .small: .subheadlineSemibold
        case .medium: .calloutSemibold
        case .large: .bodyBold
        }
    }

    /// The amount of horizontal padding to apply to the button content for this size.
    var horizontalPadding: CGFloat {
        switch self {
        case .small: 12
        case .medium: 16
        case .large: 24
        }
    }

    /// The minimum height of the button for this size.
    var minimumHeight: CGFloat {
        switch self {
        case .small: 24
        case .medium: 36
        case .large: 44
        }
    }

    /// The amount of vertical padding to apply to the button content for this size.
    var verticalPadding: CGFloat {
        switch self {
        case .small: 4
        case .medium: 8
        case .large: 12
        }
    }
}
