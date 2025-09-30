import BitwardenResources
import SwiftUI

// MARK: - PrimaryButtonStyle

/// The style for all primary buttons in this application.
///
struct PrimaryButtonStyle: ButtonStyle {
    // MARK: Properties

    @Environment(\.isEnabled) var isEnabled: Bool

    /// Whether the button is destructive.
    var isDestructive = false

    /// The size of the button.
    var size: ButtonStyleSize

    /// If this button should fill to take up as much width as possible.
    var shouldFillWidth = true

    /// The background color of this button.
    var backgroundColor: Color {
        guard isEnabled else {
            return SharedAsset.Colors.buttonFilledDisabledBackground.swiftUIColor
        }
        return isDestructive
            ? SharedAsset.Colors.error.swiftUIColor
            : SharedAsset.Colors.buttonFilledBackground.swiftUIColor
    }

    /// The color of the foreground elements in this button, including text and template
    /// images.
    var foregroundColor: Color {
        isEnabled
            ? SharedAsset.Colors.buttonFilledForeground.swiftUIColor
            : SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .multilineTextAlignment(.center)
            .styleGuide(size.fontStyle, includeLinePadding: false, includeLineSpacing: false)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil, minHeight: size.minimumHeight)
            .background(backgroundColor)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// The style for all primary buttons in this application.
    ///
    /// - Parameters:
    ///   - isDestructive: Whether the button is destructive.
    ///   - size: The size of the button. Defaults to `large`.
    ///   - shouldFillWidth: A flag indicating if this button should fill all available space.
    ///
    static func primary(
        isDestructive: Bool = false,
        shouldFillWidth: Bool = true,
        size: ButtonStyleSize = .large
    ) -> PrimaryButtonStyle {
        PrimaryButtonStyle(
            isDestructive: isDestructive,
            size: size,
            shouldFillWidth: shouldFillWidth
        )
    }
}

// MARK: Previews

#if DEBUG
#Preview("States") {
    VStack {
        Button("Hello World!") {}

        Button("Hello World!") {}
            .disabled(true)

        Button("Hello World!") {}
            .buttonStyle(.primary(isDestructive: true))
    }
    .buttonStyle(.primary())
    .padding()
}

#Preview("Sizes") {
    VStack {
        Button("Small") {}
            .buttonStyle(.primary(size: .small))

        Button("Medium") {}
            .buttonStyle(.primary(size: .medium))

        Button("Large") {}
            .buttonStyle(.primary(size: .large))
    }
    .padding()
}
#endif
