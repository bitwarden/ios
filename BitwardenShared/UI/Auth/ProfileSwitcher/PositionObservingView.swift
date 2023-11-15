import SwiftUI

// MARK: - PositionObservingView

struct PositionObservingView<Content: View>: View {
    /// The coordinate space for the view
    var coordinateSpace: CoordinateSpace

    /// The position of the view in the coordinate space
    @Binding var position: CGPoint

    /// The content of the view
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: PreferenceKey.self,
                    value: geometry.frame(in: coordinateSpace).origin
                )
            })
            .onPreferenceChange(PreferenceKey.self) { position in
                self.position = position
            }
    }
}

private extension PositionObservingView {
    struct PreferenceKey: SwiftUI.PreferenceKey {
        /// A default `offset` value for the position observing view
        static var defaultValue: CGPoint { .zero }

        /// A no-op implementation of `reduce()`
        static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
            // No-op
        }
    }
}
