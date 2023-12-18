// MARK: - AuthenticatorKeyCaptureRoute

/// A route to a specific screen in the authenticator key capture flow.
///
public enum AuthenticatorKeyCaptureRoute: Equatable, Hashable {
    /// A route to complete the scan with a manual entry
    case addManual(entry: String)

    /// A route to complete the scan with the provided value
    case complete(value: ScanResult)

    /// A route to dismiss the screen currently presented modally.
    ///
    /// - Parameter action: The action to perform on dismiss.
    case dismiss(_ action: DismissAction? = nil)

    /// A route to a capture screen.
    case screen(AuthenticatorKeyCaptureScreen)
}

/// The possible screens for the AuthenticatorKeyCaptureCoordinator.
public enum AuthenticatorKeyCaptureScreen {
    /// A screen for manual TOTP entry.
    case manual
    /// A screen for QR code capture.
    case scan
}
