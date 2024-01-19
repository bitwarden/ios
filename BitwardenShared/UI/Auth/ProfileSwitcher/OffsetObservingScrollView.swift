import SwiftUI

// MARK: - OffsetObservingScrollView

/// A scroll view that tracks its offset
///
struct OffsetObservingScrollView<Content: View>: View {
    // MARK: Properties

    /// The axes of the scroll view
    var axes: Axis.Set = [.vertical]

    /// The scroll view content
    @ViewBuilder var content: () -> Content

    /// The offset of the scroll view
    var offset: Binding<CGPoint>

    /// The `showsIndicators` state of the scroll view
    var showsIndicators = true

    // MARK: Private properties

    /// A unique coordinate space name for the view
    private let coordinateSpaceName = UUID()

    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            PositionObservingView(
                coordinateSpace: .named(coordinateSpaceName),
                position: offset,
                content: content
            )
        }
        .coordinateSpace(name: coordinateSpaceName)
    }

    // MARK: Initialization

    /// Initializes an OffsetObservingScrollView
    ///
    /// - Parameters:
    ///    - axes: The `Axis.Set` for the scroll view
    ///    - offset: A `Binding<CGPoint>` to track Scroll Offset
    ///    - showsIndicators: A flag to set scroll indicator visibility
    ///    - content: The content of the scroll view
    ///
    init(
        axes: Axis.Set = [.vertical],
        offset: Binding<CGPoint>,
        showsIndicators: Bool = true,
        content: @escaping () -> Content
    ) {
        self.axes = axes
        self.content = content
        self.offset = Binding(get: {
            offset.wrappedValue
        }, set: { newOffset in
            offset.wrappedValue = CGPoint(
                x: -newOffset.x,
                y: -newOffset.y
            )
        })
        self.showsIndicators = showsIndicators
    }
}
