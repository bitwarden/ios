import SwiftUI

/// A shape for rendering a circular progress indicator.
///
/// - Parameters:
///   - progress: A CGFloat value between 0 and 1 representing the progress. A value of 0 means no
///               progress, and 1 means full progress.
///   - clockwise: A Boolean value that determines whether the progress should fill in a clockwise
///                direction. If set to `true`, the progress fills clockwise; if `false`, it fills
///                counter-clockwise.
///
struct CircularProgressShape: Shape {
    /// The current progress of the task, represented as a fraction of a full circle.
    /// This value should be between 0.0 (no progress) and 1.0 (full progress).
    var progress: CGFloat

    /// A flag indicating whether the progress should be drawn in a clockwise direction.
    var clockwise: Bool

    /// Creates a path for the shape in the provided rectangle.
    ///
    /// This method draws an arc that represents the progress. The arc starts from the top (12 o'clock position)
    /// and sweeps either clockwise or counter-clockwise based on the `clockwise` property.
    ///
    /// - Parameter rect: The rectangle in which to draw the shape.
    /// - Returns: A `Path` object representing the circular progress shape.
    ///
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = Angle(degrees: -90)
        let endAngleDegrees = clockwise
            ? (-90 + (360 * progress))
            : (-90 - (360 * progress))
        let endAngle = Angle(degrees: endAngleDegrees)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: !clockwise
        )

        return path
    }
}
