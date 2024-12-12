import SwiftUI

// MARK: - SecondaryButtonStyle

/// The style for all secondary buttons in this application.
///
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled: Bool

    /// Whether the button is destructive.
    var isDestructive = false

    /// If this button should fill to take up as much width as possible.
    var shouldFillWidth = true

    /// The border stroke color.
    var borderColor: Color {
        if isDestructive {
            Asset.Colors.error.swiftUIColor
        } else {
            isEnabled
                ? Asset.Colors.buttonOutlinedBorder.swiftUIColor
                : Asset.Colors.buttonOutlinedDisabledBorder.swiftUIColor
        }
    }

    /// The color of the foreground elements in this button, including text and template
    /// images.
    var foregroundColor: Color {
        if isDestructive {
            Asset.Colors.error.swiftUIColor
        } else {
            isEnabled
                ? Asset.Colors.buttonOutlinedForeground.swiftUIColor
                : Asset.Colors.buttonOutlinedDisabledForeground.swiftUIColor
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .multilineTextAlignment(.center)
            .styleGuide(.bodyBold, includeLinePadding: false, includeLineSpacing: false)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil, minHeight: 44)
            .background {
                Capsule()
                    .strokeBorder(borderColor, lineWidth: 1.5)
            }
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// The style for all secondary buttons in this application.
    ///
    /// - Parameters
    ///   - isDestructive: Whether the button is destructive.
    ///   - shouldFillWidth: A flag indicating if this button should fill all available space.
    ///
    static func secondary(isDestructive: Bool = false, shouldFillWidth: Bool = true) -> SecondaryButtonStyle {
        SecondaryButtonStyle(isDestructive: isDestructive, shouldFillWidth: shouldFillWidth)
    }
}

#if DEBUG
#Preview {
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
}
#endif
