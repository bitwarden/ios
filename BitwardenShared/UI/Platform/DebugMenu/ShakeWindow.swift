import UIKit

/// A UIWindow subclass that detects and responds to shake gestures.
///
/// This window class allows you to provide a custom handler that will be called whenever a shake
/// gesture is detected. This can be particularly useful for triggering debug or testing actions only
/// in DEBUG_MENU mode, such as showing development menus or refreshing data.
///
public class ShakeWindow: UIWindow {
    /// The callback to be invoked when a shake gesture is detected.
    public var onShakeDetected: (() -> Void)?

    /// Initializes a new ShakeWindow with a specific window scene and an optional shake detection handler.
    ///
    /// - Parameters:
    ///   - windowScene: The UIWindowScene instance with which the window is associated.
    ///   - onShakeDetected: An optional closure that gets called when a shake gesture is detected.
    ///
    public init(
        windowScene: UIWindowScene,
        onShakeDetected: (() -> Void)?
    ) {
        self.onShakeDetected = onShakeDetected
        super.init(windowScene: windowScene)
    }

    /// Required initializer for UIWindow subclass. Not implemented as ShakeWindow requires
    /// a custom initialization method with shake detection handler.
    ///
    /// - Parameter coder: An NSCoder instance for decoding the window.
    ///
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Overrides the default motionEnded function to detect shake motions.
    /// If a shake motion is detected and we are in DEBUG_MENU mode,
    /// the onShakeDetected closure is called.
    ///
    /// - Parameters:
    ///   - motion: An event-subtype constant indicating the kind of motion.
    ///   - event: An object representing the event associated with the motion.
    ///
    override public func motionEnded(
        _ motion: UIEvent.EventSubtype,
        with event: UIEvent?
    ) {
        #if DEBUG_MENU
        if motion == .motionShake {
            onShakeDetected?()
        }
        #endif
    }
}
