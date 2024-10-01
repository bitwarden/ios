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
}

/// A `PreferenceKey` used to calculate the size of a view.
///
private struct ViewSizeKey: PreferenceKey {
    static var defaultValue = CGSize.zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
