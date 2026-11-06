import BitwardenResources
import SwiftUI

// MARK: - FloatingActionButtonStyle

/// The style for floating action buttons. Uses a Liquid Glass circle tinted with the filled button
/// color on iOS 26 and later, and a solid circle on earlier versions of iOS.
///
public struct FloatingActionButtonStyle: ButtonStyle {
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

    // MARK: Initialization

    /// Initializes a `FloatingActionButtonStyle`.
    ///
    /// - Parameter diameter: The diameter of the button.
    ///
    public init(diameter: CGFloat = 50) {
        self.diameter = diameter
    }

    // MARK: ButtonStyle

    public func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            configuration.label
                .foregroundStyle(foregroundColor)
                .frame(width: diameter, height: diameter)
                .glassEffect(.regular.tint(backgroundColor).interactive(), in: Circle())
        } else {
            configuration.label
                .foregroundColor(foregroundColor)
                .frame(width: diameter, height: diameter)
                .background(backgroundColor)
                .clipShape(Circle())
                .opacity(configuration.isPressed ? 0.5 : 1)
        }
    }
}

// MARK: ButtonStyle

public extension ButtonStyle where Self == FloatingActionButtonStyle {
    /// The style for floating action buttons.
    ///
    static var floatingActionButton: FloatingActionButtonStyle {
        FloatingActionButtonStyle()
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    VStack {
        Button {} label: {
            SharedAsset.Icons.plus32.swiftUIImage
                .imageStyle(.floatingActionButton)
        }

        Button {} label: {
            SharedAsset.Icons.plus32.swiftUIImage
                .imageStyle(.floatingActionButton)
        }
        .disabled(true)
    }
    .buttonStyle(.floatingActionButton)
    .padding()
}
#endif
