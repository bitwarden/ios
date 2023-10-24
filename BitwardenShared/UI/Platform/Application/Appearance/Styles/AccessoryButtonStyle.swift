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

struct AccessoryButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button {} label: {
            Asset.Images.briefcase.swiftUIImage
        }
        .buttonStyle(.accessory)
        .previewDisplayName("Enabled")

        Button {} label: {
            Asset.Images.briefcase.swiftUIImage
        }
        .buttonStyle(.accessory)
        .disabled(true)
        .previewDisplayName("Disabled")
    }
}
