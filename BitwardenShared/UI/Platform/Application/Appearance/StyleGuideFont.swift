import SwiftUI

/// A `StyleGuideFont` contains the font to use for a specific style.
///
struct StyleGuideFont {
    // MARK: Properties

    /// The font to use for the style.
    let font: Font
}

// MARK: - StyleGuideFont Constants

extension StyleGuideFont {
    /// The font for the large title style.
    static let largeTitle = StyleGuideFont(font: .system(.largeTitle))

    /// The font for the title style.
    static let title = StyleGuideFont(font: .system(.title))

    /// The font for the title2 style.
    static let title2 = StyleGuideFont(font: .system(.title2))

    /// The font for the title3 style.
    static let title3 = StyleGuideFont(font: .system(.title3))

    /// The font for the headline style.
    static let headline = StyleGuideFont(font: .system(.headline))

    /// The font for the body style.
    static let body = StyleGuideFont(font: .system(.body))

    /// The font for the monospaced body style.
    static let bodyMonospaced = StyleGuideFont(font: .system(.body, design: .monospaced))

    /// The font for the callout style.
    static let callout = StyleGuideFont(font: .system(.callout))

    /// The font for the subheadline style.
    static let subheadline = StyleGuideFont(font: .system(.subheadline))

    /// The font for the footnote style.
    static let footnote = StyleGuideFont(font: .system(.footnote))

    /// The font for the caption1 style.
    static let caption1 = StyleGuideFont(font: .system(.caption))

    /// The font for the caption2 style.
    static let caption2 = StyleGuideFont(font: .system(.caption2))

    /// The font for the caption2 style monospaced.
    static let caption2Monospaced = StyleGuideFont(font: .system(.caption2, design: .monospaced))
}

// MARK: Font + Style Guide

extension Font {
    /// Returns a style guide font for the specified style.
    ///
    /// - Parameter style: The style for which to return a font for.
    /// - Returns: A font for the specified style.
    static func styleGuide(_ style: StyleGuideFont) -> Font {
        style.font
    }
}
