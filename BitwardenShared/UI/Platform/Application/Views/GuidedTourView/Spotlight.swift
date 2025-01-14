import SwiftUI

/// A shape that represents a spotlight effect over a view.
///
struct Spotlight: Shape {
    /// The region of the view to spotlight.
    let spotlight: CGRect

    /// The corner radius of the spotlight.
    let spotlightCornerRadius: CGFloat?

    /// The shape of the spotlight.
    let spotlightShape: SpotlightShape

    /// Creates a new `Spotlight` shape.
    func path(in rect: CGRect) -> Path {
        var path = Rectangle().path(in: rect)
        let spotlightRect = spotlight
        if spotlightShape == .circle {
            path.addPath(Circle().path(in: spotlightRect))
        } else {
            path.addPath(RoundedRectangle(cornerRadius: spotlightCornerRadius ?? 0).path(in: spotlightRect))
        }
        return path
    }
}
