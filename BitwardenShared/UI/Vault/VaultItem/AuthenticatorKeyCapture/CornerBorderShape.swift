import SwiftUI

// MARK: - CornerBorderShape

/// A `Shape` that creates a border with visible corners.
///
/// This shape draws lines on each corner of a rectangle, creating a border effect where only the corners are visible.
/// It can be used to highlight edges or corners of a rectangular area without drawing a full border around the shape.
///
/// - Properties:
///   - cornerLength: The length of each line in the corners.
///   - lineWidth: The thickness of the lines used to draw the corners.
///
struct CornerBorderShape: Shape {
    // MARK: Properties

    /// The length of each line in the corners.
    let cornerLength: CGFloat

    /// The thickness of the lines used to draw the corners.
    let lineWidth: CGFloat

    // MARK: Methods

    /// Creates a path for the shape in the given rectangle.
    ///
    /// This method calculates the points for the corners based on the provided rectangle's dimensions.
    /// It draws lines at each corner of the rectangle with the specified `cornerLength` and `lineWidth`.
    ///
    /// - Parameter rect: The rectangle in which to draw the shape.
    /// - Returns: A path object that describes the shape.
    ///
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Top Left Corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))

        // Top Right Corner
        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))

        // Bottom Right Corner
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))

        // Bottom Left Corner
        path.move(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))

        return path
    }
}
