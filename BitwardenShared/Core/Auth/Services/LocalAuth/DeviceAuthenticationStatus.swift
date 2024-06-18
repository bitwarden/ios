// MARK: - DeviceAuthenticationStatus

/// The enumeration of device authentication authorization.
///
enum DeviceAuthenticationStatus: Equatable {
    /// Device auth access has been authorized or may be authorized pending a system permissions alert.
    case authorized

    /// The user cancelled the authentication action
    case cancelled

    /// Device auth access has not been determined yet.
    case notDetermined

    /// No device auth has been set, neither biometrics nor passcode nor others.
    case passcodeNotSet

    /// An unknown error case
    case unknownError(String)
}
