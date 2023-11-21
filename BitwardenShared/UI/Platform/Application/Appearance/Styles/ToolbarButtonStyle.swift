import SwiftUI

// MARK: - ToolbarButtonStyle

/// The style for all toolbar buttons in this application.
///
struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
            .opacity(configuration.isPressed ? 0.3 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == ToolbarButtonStyle {
    /// The style for all toolbar buttons in this application.
    ///
    static var toolbar: ToolbarButtonStyle {
        ToolbarButtonStyle()
    }
}

// MARK: Previews

#Preview {
    Button {} label: {
        Image(asset: Asset.Images.plus)
    }
    .buttonStyle(.toolbar)
}
