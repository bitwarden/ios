import SwiftUI

/// A shape that represents a spotlight effect over a view.
///
struct Spotlight: Shape {
    /// The region of the view to spotlight.
    let spotlight: CGRect

    /// The shape of the spotlight.
    let spotlightShape: SpotlightShape

    /// Creates a new `Spotlight` shape.
    func path(in rect: CGRect) -> Path {
        var path = Rectangle().path(in: rect)
        let spotlightRect = spotlight
        if case let .rectangle(cornerRadius) = spotlightShape {
            path.addPath(RoundedRectangle(cornerRadius: cornerRadius).path(in: spotlightRect))
        } else {
            path.addPath(Circle().path(in: spotlightRect))
        }
        return path
    }
}
