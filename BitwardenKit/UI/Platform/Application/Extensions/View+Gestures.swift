import SwiftUI

public extension View {
    /// Adds an async action to perform when this view recognizes a tap gesture.
    ///
    /// Use this method to perform the specified `action` when the user taps
    /// on the view or container `count` times.
    ///
    /// > Note: If you create a control that's functionally equivalent
    /// to a ``Button``, use ``ButtonStyle`` to create a customized button
    /// instead.
    ///
    /// In the example below, the color of the heart images changes to a random
    /// color from the `colors` array whenever the user clicks or taps on the
    /// view twice:
    ///
    ///     struct TapGestureExample: View {
    ///         let colors: [Color] = [.gray, .red, .orange, .yellow,
    ///                                .green, .blue, .purple, .pink]
    ///         @State private var fgColor: Color = .gray
    ///
    ///         var body: some View {
    ///             Image(systemName: "heart.fill")
    ///                 .resizable()
    ///                 .frame(width: 200, height: 200)
    ///                 .foregroundColor(fgColor)
    ///                 .onTapGesture(count: 2) {
    ///                     fgColor = colors.randomElement()!
    ///                 }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - count: The number of taps or clicks required to trigger the action
    ///      closure provided in `action`. Defaults to `1`.
    ///    - asyncAction: The action to perform.
    func onTapGesture(
        count: Int = 1,
        performAsync asyncAction: @escaping () async -> Void,
    ) -> some View {
        onTapGesture(
            count: count,
            perform: {
                Task {
                    await asyncAction()
                }
            },
        )
    }
}
