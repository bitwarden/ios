import BitwardenResources
import SwiftUI

// MARK: - CircleButtonStyle

/// The style for all circle buttons in this application.
///
struct CircleButtonStyle: ButtonStyle {
    // MARK: Properties

    /// A Boolean value indicating whether the button is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The background color of this button.
    var backgroundColor: Color {
        isEnabled
            ? SharedAsset.Colors.buttonFilledBackground.swiftUIColor
            : SharedAsset.Colors.buttonFilledDisabledBackground.swiftUIColor
    }

    /// The diameter of the circle in the button.
    let diameter: CGFloat

    /// The color of the foreground elements, including text and template images.
    var foregroundColor: Color {
        isEnabled
            ? SharedAsset.Colors.buttonFilledForeground.swiftUIColor
            : SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .frame(width: diameter, height: diameter)
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
            Asset.Images.plus32.swiftUIImage
                .imageStyle(
                    .init(
                        color: SharedAsset.Colors.buttonFilledForeground.swiftUIColor,
                        scaleWithFont: false,
                        width: 32,
                        height: 32
                    )
                )
        }
        .buttonStyle(CircleButtonStyle(diameter: 50))
    }
    .padding()
}
#endif
