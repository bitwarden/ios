// MARK: - AuthenticatorKeyCaptureRoute

/// A route to a specific screen in the authenticator key capture flow.
///
public enum AuthenticatorKeyCaptureRoute: Equatable, Hashable {
    /// A route to complete the scan with a manual entry
    case addManual(key: String, name: String)

    /// A route to complete the scan with the provided value
    case complete(value: ScanResult)

    /// A route to dismiss the screen currently presented modally.
    ///
    /// - Parameter action: The action to perform on dismiss.
    case dismiss(_ action: DismissAction? = nil)

    /// A route to the manual entry view.
    case manualKeyEntry
}

/// A route to a specific screen in the authenticator key capture flow.
///
public enum AuthenticatorKeyCaptureEvent: Equatable {
    /// When the app should show the scan code view.
    case showScanCode
}
