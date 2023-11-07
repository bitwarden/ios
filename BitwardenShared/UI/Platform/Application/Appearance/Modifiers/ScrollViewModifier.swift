import SwiftUI

// MARK: - ScrollViewModifier

/// A modifier that adds padded content to a `ScrollView`.
///
struct ScrollViewModifier: ViewModifier {
    // MARK: View

    func body(content: Content) -> some View {
        ScrollView {
            content
                .padding(.horizontal, 16)
                .padding([.top, .bottom], 16)
        }
        .background(Color(asset: Asset.Colors.backgroundSecondary))
    }
}
