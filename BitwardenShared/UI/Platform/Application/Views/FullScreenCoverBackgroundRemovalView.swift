import SwiftUI

/// A view that removes the background of a full-screen cover.
/// This view is being used when we present guided tour view where we need to present a full-screen cover
/// and remove the default background provided by SwiftUI.
///
struct FullScreenCoverBackgroundRemovalView: UIViewRepresentable {
    private class BackgroundRemovalView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()

            superview?.superview?.backgroundColor = .clear
        }
    }

    func makeUIView(context: Context) -> UIView {
        BackgroundRemovalView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
