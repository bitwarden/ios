import BitwardenResources
import SwiftUI

// MARK: - BitwardenBorderlessButtonStyle

/// The style for a borderless button in this application.
///
public struct BitwardenBorderlessButtonStyle: ButtonStyle {
    // MARK: Properties

    /// A value indicating whether the button is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The color of the foreground elements, including text and template images.
    var foregroundColor: Color {
        isEnabled
            ? SharedAsset.Colors.buttonOutlinedForeground.swiftUIColor
            : SharedAsset.Colors.buttonOutlinedDisabledForeground.swiftUIColor
    }

    /// If this button should fill to take up as much width as possible.
    var shouldFillWidth = false

    /// The size of the button.
    var size: ButtonStyleSize?

    // MARK: ButtonStyle

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .styleGuide(size?.fontStyle ?? .subheadlineSemibold)
            .padding(.vertical, size?.verticalPadding ?? 0)
            .padding(.horizontal, size?.horizontalPadding ?? 0)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil, minHeight: size?.minimumHeight ?? nil)
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

public extension ButtonStyle where Self == BitwardenBorderlessButtonStyle {
    /// The style for a borderless button in this application.
    ///
    /// This style does not add any padding to the button. Padding should be applied by the caller.
    ///
    static var bitwardenBorderless: BitwardenBorderlessButtonStyle {
        BitwardenBorderlessButtonStyle()
    }

    /// The style for a borderless button in this application with padding and font size based on
    /// the button size.
    ///
    /// - Parameters:
    ///   - shouldFillWidth: A flag indicating if this button should fill all available space.
    ///   - size: The size of the button, which determines the padding and font size applied.
    ///
    static func bitwardenBorderless(
        shouldFillWidth: Bool = true,
        size: ButtonStyleSize,
    ) -> BitwardenBorderlessButtonStyle {
        BitwardenBorderlessButtonStyle(shouldFillWidth: shouldFillWidth, size: size)
    }
}

// MARK: Previews

#if DEBUG
#Preview("States") {
    VStack {
        Button("Bitwarden") {}

        Button("Bitwarden") {}
            .disabled(true)
    }
    .buttonStyle(.bitwardenBorderless)
    .padding()
}

#Preview("Sizes") {
    VStack {
        Button("Small") {}
            .buttonStyle(.bitwardenBorderless(size: .small))

        Button("Medium") {}
            .buttonStyle(.bitwardenBorderless(size: .medium))

        Button("Large") {}
            .buttonStyle(.bitwardenBorderless(size: .large))
    }
    .padding()
}
#endif
