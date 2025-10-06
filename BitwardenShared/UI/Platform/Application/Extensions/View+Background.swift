import BitwardenKit
import SwiftUI

/// Helper functions extended from the `View` protocol
/// regarding applying backgrounds to such view.
///
extension View {
    /// Wraps the view in a circular colored background.
    ///
    /// - Parameters:
    ///   - color: Color of the background.
    ///   - width: Width of the circular background.
    ///   - height: Height of the circular background
    ///   - scaleWithFont: Whether to scale the frame with dynamic font size.
    /// - Returns: A wrapped view with circular colored background.
    func withCircularBackground(
        color: Color,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        scaleWithFont: Bool = true,
    ) -> some View {
        VStack {
            self
        }
        .frame(width: width ?? .infinity, height: height ?? .infinity, scaleWithFont: scaleWithFont)
        .background(color)
        .clipShape(Circle())
    }
}
