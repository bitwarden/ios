import SwiftUI

/// Helper functions extended off the `View` protocol.
///
extension View {
    /// A `ToolbarItem` for views with a dismiss button.
    ///
    /// - Parameter action: The action to perform when the dismiss button is tapped.
    ///
    /// - Returns: A `ToolbarItem` with a dismiss button.
    ///
    func cancelToolbarItem(_ action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                action()
            } label: {
                Label {
                    Text(Localizations.cancel)
                } icon: {
                    Image(asset: Asset.Images.cancel)
                        .resizable()
                        .foregroundColor(Color(asset: Asset.Colors.primaryBitwarden))
                        .frame(width: 24, height: 24)
                }
            }
        }
    }

    /// Hides a view based on the specified value.
    ///
    /// NOTE: This should only be used when the view needs to remain in the view hierarchy while hidden,
    /// which is often useful for sizing purposes (e.g. hide or swap a view without resizing the parent).
    /// Otherwise, `if condition { view }` is preferred.
    ///
    /// - Parameter hidden: `true` if the view should be hidden.
    /// - Returns The original view if `hidden` is false, or the view with the hidden modifier applied.
    ///
    @ViewBuilder
    func hidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }

    /// Applies a custom navigation bar title and title display mode to a view.
    ///
    /// - Parameters:
    ///   - title: The navigation bar title.
    ///   - titleDisplayMode: The navigation bar title display mode.
    ///
    /// - Returns: A view with a custom navigation bar.
    ///
    func navigationBar(
        title: String,
        titleDisplayMode: NavigationBarItem.TitleDisplayMode
    ) -> some View {
        modifier(NavigationBarViewModifier(
            title: title,
            navigationBarTitleDisplayMode: titleDisplayMode
        ))
    }

    /// Applies the `ScrollViewModifier` to a view.
    ///
    /// - Returns: A view within a `ScrollView`.
    ///
    func scrollView() -> some View {
        modifier(ScrollViewModifier())
    }
}
