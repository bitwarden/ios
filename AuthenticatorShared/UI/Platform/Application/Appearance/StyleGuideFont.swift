import BitwardenResources
import SwiftUI

/// A `StyleGuideFont` contains the font to use for a specific style.
///
struct StyleGuideFont {
    // MARK: Properties

    /// The font to use for the style.
    let font: SwiftUI.Font

    /// The line height for this style, in px.
    let lineHeight: CGFloat

    /// The default font size for this style, in px
    let size: CGFloat
}

// MARK: - StyleGuideFont Constants

extension StyleGuideFont {
    /// The font for the large title style.
    static let largeTitle = StyleGuideFont(font: .system(.largeTitle), lineHeight: 41, size: 34)

    /// The font for the title style.
    static let title = StyleGuideFont(font: .system(.title), lineHeight: 34, size: 28)

    /// The font for the title2 style.
    static let title2 = StyleGuideFont(font: .system(.title2), lineHeight: 28, size: 22)

    /// The font for the title3 style.
    static let title3 = StyleGuideFont(font: .system(.title3), lineHeight: 25, size: 20)

    /// The font for the headline style.
    static let headline = StyleGuideFont(font: .system(.headline), lineHeight: 22, size: 17)

    /// The font for the body style.
    static let body = StyleGuideFont(font: .system(.body), lineHeight: 22, size: 17)

    /// The font for the monospaced body style.
    static let bodyMonospaced = StyleGuideFont(font: .system(.body, design: .monospaced), lineHeight: 22, size: 17)

    /// The font for the callout style.
    static let callout = StyleGuideFont(font: .system(.callout), lineHeight: 21, size: 16)

    /// The font for the subheadline style.
    static let subheadline = StyleGuideFont(font: .system(.subheadline), lineHeight: 20, size: 15)

    /// The font for the footnote style.
    static let footnote = StyleGuideFont(font: .system(.footnote), lineHeight: 18, size: 13)

    /// The font for the caption1 style.
    static let caption1 = StyleGuideFont(font: .system(.caption), lineHeight: 16, size: 12)

    /// The font for the caption2 style.
    static let caption2 = StyleGuideFont(font: .system(.caption2), lineHeight: 13, size: 11)

    /// The font for the caption2 style monospaced.
    static let caption2Monospaced = StyleGuideFont(
        font: .system(.caption2, design: .monospaced),
        lineHeight: 13,
        size: 11
    )
}

// MARK: Font + Style Guide

private extension SwiftUI.Font {
    /// Returns a style guide font for the specified style.
    ///
    /// - Parameter style: The style for which to return a font for.
    /// - Returns: A font for the specified style.
    static func styleGuide(_ style: StyleGuideFont) -> SwiftUI.Font {
        style.font
    }
}

/// An extension to simplify adding font & line height to a View.
extension View {
    /// Sets the font and line height for the view.
    ///
    /// - Parameters:
    ///   - style: The style of the text.
    ///   - includeLineSpacing: A flag to indicate if the style should change `.lineSpacing()`.
    ///         Defaults to true.
    /// - Returns: The view with adjusted line height & font.
    ///
    func styleGuide(_ style: StyleGuideFont, includeLineSpacing: Bool = true) -> some View {
        font(.styleGuide(style))
            .lineHeight(for: style, includeLineSpacing: includeLineSpacing)
    }

    /// Sets the line height for the view.
    ///
    /// - Parameter style: The style of the text.
    /// - Returns: The view with adjusted line height.
    @ViewBuilder
    func lineHeight(for style: StyleGuideFont, includeLineSpacing: Bool) -> some View {
        if includeLineSpacing {
            padding(.vertical, (style.lineHeight - style.size) / 2)
                .lineSpacing((style.lineHeight - style.size) / 2)
                .frame(minHeight: style.lineHeight)
        } else {
            padding(.vertical, (style.lineHeight - style.size) / 2)
                .frame(minHeight: style.lineHeight)
        }
    }
}

/// An extension to simplify adding font & line height to Text.
extension Text {
    /// Sets the font and line height for the text.
    ///
    /// - Parameters:
    ///   - style: The style of the text.
    ///   - weight: The font weight. Defaults to `.regular`.
    ///   - isItalic: If the text is Italic. Defaults to `false`.
    ///   - includeLineSpacing: A flag to indicate if the style should change `.lineSpacing()`.
    ///         Defaults to true.
    ///   - monoSpacedDigit: If the text is monospaced for digits. Defaults to `false`.
    /// - Returns: The Text with adjusted line height & font.
    ///
    func styleGuide(
        _ style: StyleGuideFont,
        weight: SwiftUI.Font.Weight = .regular,
        isItalic: Bool = false,
        includeLineSpacing: Bool = true,
        monoSpacedDigit: Bool = false
    ) -> some View {
        var textWithFont = font(.styleGuide(style))
            .fontWeight(weight)
        if isItalic {
            textWithFont = textWithFont.italic()
        }
        if monoSpacedDigit {
            textWithFont = textWithFont.monospacedDigit()
        }
        return textWithFont
            .lineHeight(for: style, includeLineSpacing: includeLineSpacing)
    }
}

// MARK: Previews

#if DEBUG
struct StyleGuideFont_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            VStack(alignment: .trailing, spacing: 8) {
                Text("Large Title")
                    .styleGuide(.largeTitle)
                Text("Title")
                    .styleGuide(.title)
                Text("Title 2")
                    .styleGuide(.title2)
                Text("Title 3")
                    .styleGuide(.title3)
                Text("Headline")
                    .styleGuide(.headline)
                Text("Body")
                    .styleGuide(.body)
                Text("Body Monospaced")
                    .styleGuide(.bodyMonospaced)
                Text("Callout")
                    .styleGuide(.callout)
                Text("Subheadline")
                    .styleGuide(.subheadline)
                Text("Footnote")
                    .styleGuide(.footnote)
                Text("Caption 1")
                    .styleGuide(.caption1)
                Text("Caption 2")
                    .styleGuide(.caption2)
                Text("Caption 2 Monospaced")
                    .styleGuide(.caption2Monospaced)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Large Title")
                    .styleGuide(.largeTitle, weight: .semibold)
                Text("Title")
                    .styleGuide(.title, weight: .semibold)
                Text("Title 2")
                    .styleGuide(.title2, weight: .semibold)
                Text("Title 3")
                    .styleGuide(.title3, weight: .semibold)
                Text("Headline")
                    .styleGuide(.headline, weight: .semibold)
                Text("Body")
                    .styleGuide(.body, weight: .semibold)
                Text("Body Monospaced")
                    .styleGuide(.bodyMonospaced, weight: .semibold)
                Text("Callout")
                    .styleGuide(.callout, weight: .semibold)
                Text("Subheadline")
                    .styleGuide(.subheadline, weight: .semibold)
                Text("Footnote")
                    .styleGuide(.footnote, weight: .semibold)
                Text("Caption 1")
                    .styleGuide(.caption1, weight: .semibold)
                Text("Caption 2")
                    .styleGuide(.caption2, weight: .semibold)
                Text("Caption 2 Monospaced")
                    .styleGuide(.caption2Monospaced, weight: .semibold)
            }
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Standard vs Semi Bold")

        HStack {
            VStack(alignment: .trailing, spacing: 8) {
                Text("Large Title")
                    .styleGuide(.largeTitle)
                Text("Title")
                    .styleGuide(.title)
                Text("Title 2")
                    .styleGuide(.title2)
                Text("Title 3")
                    .styleGuide(.title3)
                Text("Headline")
                    .styleGuide(.headline)
                Text("Body")
                    .styleGuide(.body)
                Text("Body Monospaced")
                    .styleGuide(.bodyMonospaced)
                Text("Callout")
                    .styleGuide(.callout)
                Text("Subheadline")
                    .styleGuide(.subheadline)
                Text("Footnote")
                    .styleGuide(.footnote)
                Text("Caption 1")
                    .styleGuide(.caption1)
                Text("Caption 2")
                    .styleGuide(.caption2)
                Text("Caption 2 Monospaced")
                    .styleGuide(.caption2Monospaced)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Large Title")
                    .styleGuide(.largeTitle, isItalic: true)
                Text("Title")
                    .styleGuide(.title, isItalic: true)
                Text("Title 2")
                    .styleGuide(.title2, isItalic: true)
                Text("Title 3")
                    .styleGuide(.title3, isItalic: true)
                Text("Headline")
                    .styleGuide(.headline, isItalic: true)
                Text("Body")
                    .styleGuide(.body, isItalic: true)
                Text("Body Monospaced")
                    .styleGuide(.bodyMonospaced, isItalic: true)
                Text("Callout")
                    .styleGuide(.callout, isItalic: true)
                Text("Subheadline")
                    .styleGuide(.subheadline, isItalic: true)
                Text("Footnote")
                    .styleGuide(.footnote, isItalic: true)
                Text("Caption 1")
                    .styleGuide(.caption1, isItalic: true)
                Text("Caption 2")
                    .styleGuide(.caption2, isItalic: true)
                Text("Caption 2 Monospaced")
                    .styleGuide(.caption2Monospaced, isItalic: true)
            }
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Standard vs Italic")

        HStack {
            VStack(alignment: .trailing, spacing: 8) {
                Text("Large Title")
                    .styleGuide(.largeTitle)
                Text("Title")
                    .styleGuide(.title)
                Text("Title 2")
                    .styleGuide(.title2)
                Text("Title 3")
                    .styleGuide(.title3)
                Text("Headline")
                    .styleGuide(.headline)
                Text("Body")
                    .styleGuide(.body)
                Text("Body Monospaced")
                    .styleGuide(.bodyMonospaced)
                Text("Callout")
                    .styleGuide(.callout)
                Text("Subheadline")
                    .styleGuide(.subheadline)
                Text("Footnote")
                    .styleGuide(.footnote)
                Text("Caption 1")
                    .styleGuide(.caption1)
                Text("Caption 2")
                    .styleGuide(.caption2)
                Text("Caption 2 Monospaced")
                    .styleGuide(.caption2Monospaced)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Large Title")
                    .styleGuide(.largeTitle, weight: .semibold, isItalic: true)
                Text("Title")
                    .styleGuide(.title, weight: .semibold, isItalic: true)
                Text("Title 2")
                    .styleGuide(.title2, weight: .semibold, isItalic: true)
                Text("Title 3")
                    .styleGuide(.title3, weight: .semibold, isItalic: true)
                Text("Headline")
                    .styleGuide(.headline, weight: .semibold, isItalic: true)
                Text("Body")
                    .styleGuide(.body, weight: .semibold, isItalic: true)
                Text("Body Monospaced")
                    .styleGuide(.bodyMonospaced, weight: .semibold, isItalic: true)
                Text("Callout")
                    .styleGuide(.callout, weight: .semibold, isItalic: true)
                Text("Subheadline")
                    .styleGuide(.subheadline, weight: .semibold, isItalic: true)
                Text("Footnote")
                    .styleGuide(.footnote, weight: .semibold, isItalic: true)
                Text("Caption 1")
                    .styleGuide(.caption1, weight: .semibold, isItalic: true)
                Text("Caption 2")
                    .styleGuide(.caption2, weight: .semibold, isItalic: true)
                Text("Caption 2 Monospaced")
                    .styleGuide(.caption2Monospaced, weight: .semibold, isItalic: true)
            }
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Standard vs Bold Italic")

        VStack(alignment: .leading) {
            Button("Sample Button", action: {})
                .buttonStyle(.primary())
                .styleGuide(.callout)
            Toggle("Toggle", isOn: .init(get: { true }, set: { _ in }))
                .toggleStyle(.bitwarden)
            Group {
                Text(Localizations.important + ": ")
                    .bold() +
                    Text(Localizations.bitwardenCannotResetALostOrForgottenMasterPassword)
            }
            .styleGuide(.footnote)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Views")
    }
}
#endif
