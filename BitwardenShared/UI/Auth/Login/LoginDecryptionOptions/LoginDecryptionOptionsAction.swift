// MARK: - LoginDecryptionOptionsAction

/// Actions that can be processed by a `LoginDecryptionOptionsProcessor`.
enum LoginDecryptionOptionsAction: Equatable {
    /// The remember device was toggled.
    case toggleRememberDevice(Bool)
}
