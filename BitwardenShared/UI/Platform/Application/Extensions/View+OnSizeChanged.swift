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
    /// - Parameters:
    ///   - id: A unique identifier for the view.
    ///   - perform: A closure called when the size or origin of the view changes.
    /// - Returns: A copy of the view with the sizing and origin modifier applied.
    ///
    func onFrameChanged(id: String, perform: @escaping (String, CGPoint, CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ViewFrameKey.self,
                        value: [
                            id: CGRect(
                                origin: geometry.frame(in: .global).origin,
                                size: geometry.size
                            ),
                        ]
                    )
            }
        )
        .onPreferenceChange(ViewFrameKey.self) { value in
            if let frame = value[id] {
                perform(id, frame.origin, frame.size)
            }
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
struct ViewFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        let newValue = nextValue().filter { $0.value.size != .zero }
        value.merge(newValue) { _, new in new }
    }
}
