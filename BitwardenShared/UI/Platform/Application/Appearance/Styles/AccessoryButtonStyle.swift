import BitwardenResources
import SwiftUI

// MARK: - AccessoryButtonStyle

/// The style for an accessory button.
///
struct AccessoryButtonStyle: ButtonStyle {
    /// A value indicating whether the button is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 24, height: 24)
            .foregroundColor(
                isEnabled
                    ? SharedAsset.Colors.iconPrimary.swiftUIColor
                    : SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor
            )
            .opacity(configuration.isPressed ? 0.5 : 1)
            .contentShape(Rectangle())
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == AccessoryButtonStyle {
    /// The style for an accessory buttons in this application.
    ///
    static var accessory: AccessoryButtonStyle {
        AccessoryButtonStyle()
    }
}

// MARK: Previews

#if DEBUG
#Preview("Enabled") {
    Button {} label: {
        Asset.Images.copy24.swiftUIImage
    }
    .buttonStyle(.accessory)
}

#Preview("Disabled") {
    Button {} label: {
        Asset.Images.copy24.swiftUIImage
    }
    .buttonStyle(.accessory)
    .disabled(true)
}
#endif
