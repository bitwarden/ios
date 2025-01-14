import SwiftUI

extension View {
    /// A view modifier that calculates the size of the containing view.
    ///
    /// - Parameter perform: A closure called when the size of the view changes.
    /// - Returns: A copy of the view with the sizing modifier applied.
    ///
    func onSizeChanged(perform: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ViewSizeKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(ViewSizeKey.self, perform: perform)
    }

    /// A view modifier that calculates the origin and size of the containing view.
    ///
    /// - Parameter perform: A closure called when the size or origin of the view changes.
    /// - Returns: A copy of the view with the sizing and origin modifier applied.
    ///
    func onFrameChanged(perform: @escaping (CGPoint, CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ViewFrameKey.self,
                        value: ViewFrame(
                            origin: geometry.frame(in: .global).origin,
                            size: geometry.size
                        )
                    )
            }
        )
        .onPreferenceChange(ViewFrameKey.self) { value in
            perform(value.origin, value.size)
        }
    }
}

/// A `PreferenceKey` used to calculate the size of a view.
///
private struct ViewSizeKey: PreferenceKey {
    static var defaultValue = CGSize.zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

/// A `PreferenceKey` used to calculate the size and origin of a view.
///
private struct ViewFrameKey: PreferenceKey {
    static var defaultValue = ViewFrame(origin: .zero, size: .zero)

    static func reduce(value: inout ViewFrame, nextValue: () -> ViewFrame) {
        if nextValue() != defaultValue {
            value = nextValue()
        }
    }
}

/// A structure that represents the origin and size of a view.
struct ViewFrame: Equatable {
    /// The origin of the view.
    var origin: CGPoint

    /// The size of the view.
    var size: CGSize

    static func == (lhs: ViewFrame, rhs: ViewFrame) -> Bool {
        lhs.size == rhs.size && lhs.origin == rhs.origin
    }
}
