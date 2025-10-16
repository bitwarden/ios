import SwiftUI

public extension View {
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
            },
        )
        .onPreferenceChange(ViewSizeKey.self, perform: perform)
    }

    /// A view modifier that calculates the origin and size of the containing view.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the view. This is necessary to distinguish between multiple
    ///         views that might be using the same modifier, ensuring that the correct view's changes
    ///         are tracked and handled.
    ///   - perform: A closure called when the size or origin of the view changes. The closure receives
    ///              the new size and origin of the view as parameters.
    /// - Returns: A copy of the view with the sizing and origin modifier applied.
    ///
    func onFrameChanged(id: String, perform: @escaping (CGPoint, CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ViewFrameKey.self,
                        value: [
                            id: CGRect(
                                origin: geometry.frame(in: .global).origin,
                                size: geometry.size,
                            ),
                        ],
                    )
            },
        )
        .onPreferenceChange(ViewFrameKey.self) { value in
            if let frame = value[id] {
                perform(frame.origin, frame.size)
            }
        }
    }
}

/// A `PreferenceKey` used to calculate the size of a view.
///
private struct ViewSizeKey: PreferenceKey {
    static var defaultValue = CGSize.zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        guard nextValue() != defaultValue else { return }
        value = nextValue()
    }
}

/// A `PreferenceKey` used to calculate the size and origin of a view.
///
/// The `ViewFrameKey` stores a dictionary that maps a view's identifier (as a `String`)
/// to the last received frame (`CGRect`) for that view. This allows tracking the size
/// and position of views within a SwiftUI hierarchy.
///
struct ViewFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        let newValue = nextValue().filter { $0.value.size != .zero }
        value.merge(newValue) { _, new in new }
    }
}
