import BitwardenResources
import SwiftUI

/// A loading overlay which shows a circular activity indicator with text below it.
///
struct LoadingOverlayView: View {
    // MARK: Properties

    /// The state used to configure the display of the view.
    let state: LoadingOverlayState

    // MARK: View

    var body: some View {
        VStack(spacing: 24) {
            CircularActivityIndicator()

            Text(state.title)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .styleGuide(.headline, weight: .semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor.opacity(0.9).ignoresSafeArea())
        .accessibilityIdentifier("LoadingViewImage")
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    LoadingOverlayView(state: LoadingOverlayState(title: "Progress..."))
}
#endif
