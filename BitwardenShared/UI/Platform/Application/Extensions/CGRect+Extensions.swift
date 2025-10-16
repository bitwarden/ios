import Foundation

/// A extension to `CGRect` that allows enlarging the rect by a given value.
extension CGRect {
    /// Returns a new `CGRect` that is enlarged by the given value, will add the value to each side of the rect.
    ///
    /// - Parameter value: The value to enlarge the `CGRect` by.
    /// - Returns: A new `CGRect` that is enlarged by the given value.
    ///
    func enlarged(by value: CGFloat) -> CGRect {
        CGRect(
            x: origin.x - value,
            y: origin.y - value,
            width: size.width + 2 * value,
            height: size.height + 2 * value,
        )
    }
}
