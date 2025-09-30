import BitwardenResources
import SwiftUI

// swiftlint:disable file_length

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

    /// The text style for the font, used to determine how the font scales with dynamic type.
    let textStyle: SwiftUI.Font.TextStyle

    // MARK: Initialization

    /// Initialize a `StyleGuideFont`.
    ///
    /// - Parameters:
    ///   - font: The font to use for the style.
    ///   - lineHeight: The line height for this style, in px.
    ///   - size: The default font size for this style, in px
    ///   - textStyle: The text style for the font, used to determine how the font scales with dynamic type.
    ///
    init(font: SwiftUI.Font, lineHeight: CGFloat, size: CGFloat, textStyle: SwiftUI.Font.TextStyle = .body) {
        self.font = font
        self.lineHeight = lineHeight
        self.size = size
        self.textStyle = textStyle
    }
}

extension StyleGuideFont {
    /// Initialize a `StyleGuideFont` from a `FontConvertible`.
    ///
    /// - Parameters:
    ///   - font: The `FontConvertible` font for this style.
    ///   - lineHeight: The line height for this style, in px.
    ///   - size: The default font size for this style, in px.
    ///   - textStyle: The text style for the font, used to determine how the font scales with dynamic type.
    ///
    init(font: FontConvertible, lineHeight: CGFloat, size: CGFloat, textStyle: SwiftUI.Font.TextStyle) {
        self.font = font.swiftUIFont(size: size, relativeTo: textStyle)
        self.lineHeight = lineHeight
        self.size = size
        self.textStyle = textStyle
    }

    /// Returns a `StyleGuideFont` that uses the DMSans font.
    ///
    /// - Parameters:
    ///   - lineHeight: The line height for this style, in px.
    ///   - size: The default font size for this style, in px.
    ///   - textStyle: The text style for the font, used to determine how the font scales with dynamic type.
    /// - Returns: A `StyleGuideFont` that uses the DMSans font.
    ///
    static func dmSans(lineHeight: CGFloat, size: CGFloat, textStyle: SwiftUI.Font.TextStyle) -> StyleGuideFont {
        FontFamily.registerAllCustomFonts()
        return self.init(font: FontFamily.DMSans.regular, lineHeight: lineHeight, size: size, textStyle: textStyle)
    }

    /// Returns a new `StyleGuideFont` with same properties but different font.
    ///
    /// - Parameter font: The `FontConvertible` font for this style.
    /// - Returns: A `StyleGuideFont` modified to use the specified font.
    ///
    private func with(font: FontConvertible) -> StyleGuideFont {
        StyleGuideFont(
            font: font,
            lineHeight: lineHeight,
            size: size,
            textStyle: textStyle
        )
    }
}

// MARK: - StyleGuideFont Constants

extension StyleGuideFont {
    /// The font for the huge title style.
    static let hugeTitle = StyleGuideFont.dmSans(lineHeight: 41, size: 34, textStyle: .largeTitle)

    /// The font for the large title style.
    static let largeTitle = StyleGuideFont.dmSans(lineHeight: 32, size: 26, textStyle: .largeTitle)

    /// The font for the title style.
    static let title = StyleGuideFont.dmSans(lineHeight: 28, size: 22, textStyle: .title)

    /// The font for the title2 style.
    static let title2 = StyleGuideFont.dmSans(lineHeight: 22, size: 17, textStyle: .title2)

    /// The font for the title3 style.
    static let title3 = StyleGuideFont.dmSans(lineHeight: 21, size: 16, textStyle: .title3)

    /// The font for the headline style.
    static let headline = StyleGuideFont.dmSans(lineHeight: 28, size: 15, textStyle: .headline)

    /// The font for the body style.
    static let body = StyleGuideFont.dmSans(lineHeight: 20, size: 15, textStyle: .body)

    /// The font for the bold body style.
    static let bodyBold = body.with(font: FontFamily.DMSans.bold)

    /// The font for the monospaced body style.
    static let bodyMonospaced = StyleGuideFont(font: .system(.body, design: .monospaced), lineHeight: 22, size: 17)

    /// The font for the bold semibody style.
    static let bodySemibold = body.with(font: FontFamily.DMSans.semiBold)

    /// The font for the callout style.
    static let callout = StyleGuideFont.dmSans(lineHeight: 18, size: 13, textStyle: .callout)

    /// The font for the callout semibold style.
    static let calloutSemibold = callout.with(font: FontFamily.DMSans.semiBold)

    /// The font for the subheadline style.
    static let subheadline = StyleGuideFont.dmSans(lineHeight: 16, size: 12, textStyle: .subheadline)

    /// The font for the subheadline semibold style.
    static let subheadlineSemibold = subheadline.with(font: FontFamily.DMSans.semiBold)

    /// The font for the footnote style.
    static let footnote = StyleGuideFont.dmSans(lineHeight: 18, size: 12, textStyle: .footnote)

    /// The font for the caption1 style.
    static let caption1 = StyleGuideFont.dmSans(lineHeight: 18, size: 12, textStyle: .caption)

    /// The font for the caption2 style.
    static let caption2 = StyleGuideFont.dmSans(lineHeight: 13, size: 11, textStyle: .caption2)

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
    ///   - includeLinePadding: A flag to indicate if the style should apply padding around the
    ///     view to account for the font's line height. Defaults to `true`.
    ///   - includeLineSpacing: A flag to indicate if the style should change `.lineSpacing()`.
    ///     Defaults to `true`. When `true`, this will set line spacing and padding.
    /// - Returns: The view with adjusted line height & font.
    ///
    func styleGuide(
        _ style: StyleGuideFont,
        includeLinePadding: Bool = true,
        includeLineSpacing: Bool = true
    ) -> some View {
        font(.styleGuide(style))
            .lineHeight(
                for: style,
                includeLinePadding: includeLinePadding,
                includeLineSpacing: includeLineSpacing
            )
    }

    /// Sets the line height for the view.
    ///
    /// - Parameters:
    ///   - style: The style of the text.
    ///   - includeLinePadding: A flag to indicate if the style should apply padding around the
    ///     view to account for the font's line height. Defaults to `true`.
    ///   - includeLineSpacing: A flag to indicate if the style should change `.lineSpacing()`.
    ///     Defaults to `true`. When `true`, this will set line spacing and padding.
    /// - Returns: The view with adjusted line height.
    @ViewBuilder
    func lineHeight(
        for style: StyleGuideFont,
        includeLinePadding: Bool,
        includeLineSpacing: Bool
    ) -> some View {
        if includeLineSpacing {
            padding(.vertical, (style.lineHeight - style.size) / 2)
                .lineSpacing((style.lineHeight - style.size) / 2)
                .frame(minHeight: style.lineHeight)
        } else if includeLinePadding {
            padding(.vertical, (style.lineHeight - style.size) / 2)
                .frame(minHeight: style.lineHeight)
        } else {
            self
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
    ///   - includeLinePadding: A flag to indicate if the style should apply padding around the
    ///     view to account for the font's line height. Defaults to `true`.
    ///   - includeLineSpacing: A flag to indicate if the style should change `.lineSpacing()`.
    ///     Defaults to `true`. When `true`, this will set line spacing and padding.
    ///   - monoSpacedDigit: If the text is monospaced for digits. Defaults to `false`.
    /// - Returns: The Text with adjusted line height & font.
    ///
    func styleGuide(
        _ style: StyleGuideFont,
        weight: SwiftUI.Font.Weight = .regular,
        isItalic: Bool = false,
        includeLinePadding: Bool = true,
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
            .lineHeight(
                for: style,
                includeLinePadding: includeLinePadding,
                includeLineSpacing: includeLineSpacing
            )
    }
}

// MARK: Previews

#if DEBUG
struct StyleGuideFont_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            VStack(alignment: .trailing, spacing: 8) {
                Text("Huge Title")
                    .styleGuide(.hugeTitle)
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
                Text("Huge Title")
                    .styleGuide(.hugeTitle, weight: .semibold)
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
                Text("Huge Title")
                    .styleGuide(.hugeTitle)
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
                Text("Huge Title")
                    .styleGuide(.hugeTitle, isItalic: true)
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
                Text("Huge Title")
                    .styleGuide(.hugeTitle)
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
                Text("Huge Title")
                    .styleGuide(.hugeTitle, weight: .semibold, isItalic: true)
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
            .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Views")
    }
}
#endif
