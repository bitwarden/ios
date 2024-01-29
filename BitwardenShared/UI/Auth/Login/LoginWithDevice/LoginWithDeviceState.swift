// MARK: - LoginWithDeviceState

/// An object that defines the current state of the `LoginWithDeviceView`.
///
struct LoginWithDeviceState: Equatable {
    /// The user's email.
    var email: String = ""

    /// The fingerprint phrase.
    var fingerprintPhrase: String? = ""
}
