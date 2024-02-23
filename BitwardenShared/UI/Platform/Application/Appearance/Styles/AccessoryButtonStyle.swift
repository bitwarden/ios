import SwiftUI

// MARK: - AccessoryButtonStyle

/// The style for an accessory button.
///
struct AccessoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 14, height: 14)
            .padding(10)
            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
            .background(Asset.Colors.fillTertiary.swiftUIColor)
            .clipShape(Circle())
            .opacity(configuration.isPressed ? 0.5 : 1)
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
#Preview {
    Button {} label: {
        Asset.Images.bwiProvider.swiftUIImage
    }
    .buttonStyle(.accessory)
    .previewDisplayName("Enabled")
}

#Preview {
    Button {} label: {
        Asset.Images.bwiProvider.swiftUIImage
    }
    .buttonStyle(.accessory)
    .disabled(true)
    .previewDisplayName("Disabled")
}
#endif
