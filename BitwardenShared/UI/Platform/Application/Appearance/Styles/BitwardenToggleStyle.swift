import SwiftUI

// MARK: - BitwardenToggleStyle

/// A tinted toggle style.
///
struct BitwardenToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .tint(Color(asset: Asset.Colors.primaryBitwarden))
    }
}

// MARK: ToggleStyle

extension ToggleStyle where Self == BitwardenToggleStyle {
    /// The style for toggles used in this application.
    static var bitwarden: BitwardenToggleStyle { BitwardenToggleStyle() }
}
