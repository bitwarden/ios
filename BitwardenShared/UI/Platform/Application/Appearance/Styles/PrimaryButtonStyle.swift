import SwiftUI

// MARK: - PrimaryButtonStyle

/// The style for all primary buttons in this application.
///
struct PrimaryButtonStyle: ButtonStyle {
    // MARK: Types

    /// The different sizes that the button style supports.
    enum Size {
        case medium
        case large

        /// The font style of the button label for this size.
        var fontStyle: StyleGuideFont {
            switch self {
            case .medium: .calloutBold
            case .large: .bodyBold
            }
        }

        /// The minimum height of the button for this size.
        var minimumHeight: CGFloat {
            switch self {
            case .medium: 36
            case .large: 44
            }
        }

        /// The amount of vertical padding to apply to the button content for this size.
        var verticalPadding: CGFloat {
            switch self {
            case .medium: 8
            case .large: 12
            }
        }
    }

    // MARK: Properties

    @Environment(\.isEnabled) var isEnabled: Bool

    /// Whether the button is destructive.
    var isDestructive = false

    /// The size of the button.
    var size: Size

    /// If this button should fill to take up as much width as possible.
    var shouldFillWidth = true

    /// The background color of this button.
    var backgroundColor: Color {
        guard isEnabled else {
            return Asset.Colors.buttonFilledDisabledBackground.swiftUIColor
        }
        return isDestructive
            ? Asset.Colors.error.swiftUIColor
            : Asset.Colors.buttonFilledBackground.swiftUIColor
    }

    /// The color of the foreground elements in this button, including text and template
    /// images.
    var foregroundColor: Color {
        isEnabled
            ? Asset.Colors.buttonFilledForeground.swiftUIColor
            : Asset.Colors.buttonFilledDisabledForeground.swiftUIColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .multilineTextAlignment(.center)
            .styleGuide(size.fontStyle, includeLinePadding: false, includeLineSpacing: false)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, 20)
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
        size: PrimaryButtonStyle.Size = .large,
        shouldFillWidth: Bool = true
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
        Button("Medium") {}
            .buttonStyle(.primary(size: .medium))

        Button("Large") {}
            .buttonStyle(.primary(size: .large))
    }
    .padding()
}
#endif
