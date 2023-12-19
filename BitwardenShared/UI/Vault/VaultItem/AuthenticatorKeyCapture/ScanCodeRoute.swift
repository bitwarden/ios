// MARK: - ScanCodeRoute

/// A route to a specific screen in the scan code screen.
///
public enum ScanCodeRoute: Equatable, Hashable {
    /// A route to complete the scan with the provided value
    case complete(value: ScanResult)

    /// A route that dismisses a presented sheet.
    case dismiss

    /// A route to the scan code screen.
    case scanCode

    /// A route to the manual TOTP entry screen.
    case setupTotpManual
}
