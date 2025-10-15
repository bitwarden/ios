import BitwardenResources
import SwiftUI

// MARK: - CircleMenuStyle

/// A custom `MenuStyle` for styling `Menu` components as a circular button. On iOS 17+, a `Menu`
/// can be styled with a `ButtonStyle` instead of a `MenuStyle` (prior to iOS 17, a `ButtonStyle`
/// has no effect on a `Menu`). `ButtonStyle` also allows using `configuration.isPressed` to style
/// the pressed state.
///
@available(iOS, deprecated: 17, message: "Prefer using CircleButtonStyle to style Menu buttons on iOS 17+")
public struct CircleMenuStyle: MenuStyle {
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

    /// Initializes a `CircleMenuStyle`.
    ///
    /// - Parameters:
    ///   - diameter: The diameter of the button.
    public init(diameter: CGFloat) {
        self.diameter = diameter
    }

    public func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .foregroundColor(foregroundColor)
            .frame(width: diameter, height: diameter)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    Menu {
        Button("First") {}
        Button("Second") {}
    } label: {
        SharedAsset.Icons.plus32.swiftUIImage
    }
    .menuStyle(CircleMenuStyle(diameter: 50))
}
#endif
