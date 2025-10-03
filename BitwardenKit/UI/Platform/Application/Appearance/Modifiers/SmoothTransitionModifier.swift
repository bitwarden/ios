import SwiftUI

/// A custom view modifier to apply smooth transition effects and animations.
///
struct SmoothTransitionModifier<V: Equatable>: ViewModifier {
    /// The animation to apply to the view.
    let animation: Animation

    /// The value that triggers the animation.
    let value: V

    func body(content: Content) -> some View {
        content
            .animation(animation, value: value)
            .modifier(SmoothTransitionEffect())
    }
}

/// A custom geometry effect that applies a smooth transition effect to a view.
/// This effect allows for animating the translation of a view along the X and Y axes.
struct SmoothTransitionEffect: GeometryEffect {
    /// The animatable data representing the translation values for the X and Y axes.
    var animatableData: AnimatablePair<CGFloat, CGFloat>

    /// Initializes a new instance of the `SmoothTransitionEffect` with default translation values.
    init() {
        animatableData = AnimatablePair(0, 0)
    }

    /// Computes the projection transform for the given size, applying the translation effect.
    ///
    /// - Parameter size: The size of the view to which the effect is applied.
    /// - Returns: A `ProjectionTransform` representing the translation transformation.
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = CGAffineTransform(translationX: animatableData.first, y: animatableData.second)
        return ProjectionTransform(translation)
    }
}

// MARK: - Extensions

public extension View {
    /// A view modifier that applies a smooth transition effect to the view.
    ///
    func smoothTransition<V: Equatable>(animation: Animation, value: V) -> some View {
        modifier(SmoothTransitionModifier(animation: animation, value: value))
    }
}
