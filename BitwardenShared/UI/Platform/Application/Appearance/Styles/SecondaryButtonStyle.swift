import BitwardenResources
import SwiftUI

// MARK: - SecondaryButtonStyle

/// The style for all secondary buttons in this application.
///
struct SecondaryButtonStyle: ButtonStyle {
    // MARK: Properties

    @Environment(\.isEnabled) var isEnabled: Bool

    /// Whether the button is destructive.
    var isDestructive = false

    /// Whether the button's colors are reversed.
    var isReversed = false

    /// If this button should fill to take up as much width as possible.
    var shouldFillWidth = true

    /// The size of the button.
    var size: ButtonStyleSize

    // MARK: Computed Properties

    /// The border stroke color.
    var borderColor: Color {
        if isDestructive {
            SharedAsset.Colors.error.swiftUIColor
        } else if isReversed {
            SharedAsset.Colors.buttonOutlinedBorderReversed.swiftUIColor
        } else {
            isEnabled
                ? SharedAsset.Colors.buttonOutlinedBorder.swiftUIColor
                : SharedAsset.Colors.buttonOutlinedDisabledBorder.swiftUIColor
        }
    }

    /// The color of the foreground elements in this button, including text and template
    /// images.
    var foregroundColor: Color {
        if isDestructive {
            SharedAsset.Colors.error.swiftUIColor
        } else if isReversed {
            SharedAsset.Colors.buttonOutlinedForegroundReversed.swiftUIColor
        } else {
            isEnabled
                ? SharedAsset.Colors.buttonOutlinedForeground.swiftUIColor
                : SharedAsset.Colors.buttonOutlinedDisabledForeground.swiftUIColor
        }
    }

    // MARK: ButtonStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .multilineTextAlignment(.center)
            .styleGuide(size.fontStyle, includeLinePadding: false, includeLineSpacing: false)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil, minHeight: size.minimumHeight)
            .background {
                Capsule()
                    .strokeBorder(borderColor, lineWidth: 1.5)
            }
            .contentShape(Capsule())
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// The style for all secondary buttons in this application.
    ///
    /// - Parameters:
    ///   - isDestructive: Whether the button is destructive.
    ///   - isReversed: Whether the button's colors are reversed.
    ///   - shouldFillWidth: A flag indicating if this button should fill all available space.
    ///   - size: The size of the button. Defaults to `large`.
    ///
    static func secondary(
        isDestructive: Bool = false,
        isReversed: Bool = false,
        shouldFillWidth: Bool = true,
        size: ButtonStyleSize = .large
    ) -> SecondaryButtonStyle {
        SecondaryButtonStyle(
            isDestructive: isDestructive,
            isReversed: isReversed,
            shouldFillWidth: shouldFillWidth,
            size: size
        )
    }
}

#if DEBUG
#Preview("States") {
    VStack {
        Group {
            Button("Hello World!") {}

            Button("Hello World!") {}
                .disabled(true)
        }
        .buttonStyle(.secondary())

        Button("Hello World!") {}
            .buttonStyle(.secondary(isDestructive: true))
    }
    .padding()

    VStack {
        Button("Hello World!") {}
            .buttonStyle(.secondary(isReversed: true))
    }
    .padding()
    .background(SharedAsset.Colors.backgroundAlert.swiftUIColor)
}

#Preview("Sizes") {
    VStack {
        Button("Small") {}
            .buttonStyle(.secondary(size: .small))

        Button("Medium") {}
            .buttonStyle(.secondary(size: .medium))

        Button("Large") {}
            .buttonStyle(.secondary(size: .large))
    }
    .padding()
}
#endif
