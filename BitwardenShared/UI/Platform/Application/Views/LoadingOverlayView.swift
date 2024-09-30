import SwiftUI

/// A loading overlay view which shows an activity indicator with text below it.
///
struct LoadingOverlayView: View {
    // MARK: Properties

    @Environment(\.colorScheme) private var colorScheme

    /// The state used to configure the display of the view.
    let state: LoadingOverlayState

    var body: some View {
        ProgressView {
            Text(state.title)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(width: 270, alignment: .center)
        .background(
            ZStack {
                Asset.Colors.Legacy.materialRegularBase.swiftUIColor
                Asset.Colors.Legacy.materialRegularBlend.swiftUIColor
                    .blendMode(colorScheme == .light ? .colorDodge : .overlay)
            }
            .compositingGroup()
        )
        .cornerRadius(14)
        .controlSize(.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Asset.Colors.Legacy.backgroundDimmed.swiftUIColor.ignoresSafeArea())
    }
}

#if DEBUG
#Preview {
    LoadingOverlayView(state: LoadingOverlayState(title: "Progress..."))
}

#Preview {
    LoadingOverlayView(state: LoadingOverlayState(title: "Progress..."))
        .preferredColorScheme(.dark)
}
#endif
