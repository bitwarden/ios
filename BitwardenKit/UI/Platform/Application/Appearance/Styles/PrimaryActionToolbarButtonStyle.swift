import BitwardenResources
import SwiftUI

// MARK: - PrimaryActionToolbarButtonStyle

/// The style for primary action toolbar buttons. Uses the prominent style on iOS 26 and later so
/// the button stands out on the Liquid Glass toolbar, and the plain toolbar style on earlier
/// versions of iOS.
///
public struct PrimaryActionToolbarButtonStyle: PrimitiveButtonStyle {
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The color of the foreground elements in this button, including text and template images.
    var foregroundColor: Color {
        isEnabled
            ? SharedAsset.Colors.buttonFilledForeground.swiftUIColor
            : SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor
    }

    public func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            // The foreground color is applied to the label, rather than the button, because the
            // prominent style sets its own label color, which overrides a color set on the button.
            // That system color isn't consistent across iOS versions.
            Button(role: configuration.role, action: configuration.trigger) {
                configuration.label
                    .foregroundStyle(foregroundColor)
            }
            .buttonStyle(.borderedProminent)
            .tint(SharedAsset.Colors.buttonFilledBackground.swiftUIColor)
        } else {
            Button(configuration)
                .buttonStyle(.toolbar)
        }
    }
}

// MARK: PrimitiveButtonStyle

public extension PrimitiveButtonStyle where Self == PrimaryActionToolbarButtonStyle {
    /// The style for primary action toolbar buttons.
    ///
    static var primaryActionToolbar: PrimaryActionToolbarButtonStyle {
        PrimaryActionToolbarButtonStyle()
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    VStack {
        Button("Hello World!") {}

        Button("Hello World!") {}
            .disabled(true)
    }
    .buttonStyle(.primaryActionToolbar)
    .padding()
}
#endif
