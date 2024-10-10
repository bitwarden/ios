import SwiftUI

// MARK: - CircleButtonStyle

/// The style for all primary buttons in this application.
///
struct CircleButtonStyle: ButtonStyle {
    // MARK: Properties

    /// A Boolean value indicating whether the button is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The background color of this button.
    var backgroundColor: Color {
        isEnabled
            ? Asset.Colors.buttonFilledBackground.swiftUIColor
            : Asset.Colors.buttonFilledDisabledBackground.swiftUIColor
    }

    /// The color of the foreground elements, including text and template images.
    var foregroundColor: Color {
        isEnabled
            ? Asset.Colors.buttonFilledForeground.swiftUIColor
            : Asset.Colors.buttonFilledDisabledForeground.swiftUIColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(8)
            .background(backgroundColor)
            .clipShape(Circle())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    VStack {
        Button {} label: {
            Asset.Images.plus.swiftUIImage
                .imageStyle(
                    .init(
                        color: Asset.Colors.buttonFilledForeground.swiftUIColor,
                        scaleWithFont: false,
                        width: 32,
                        height: 32
                    )
                )
        }
        .buttonStyle(CircleButtonStyle())
    }
    .padding()
}
#endif
