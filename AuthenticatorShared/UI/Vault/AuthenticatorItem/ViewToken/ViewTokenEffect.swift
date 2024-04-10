// MARK: - ViewTokenEffect

/// Asynchronous effects that can be processed by a `ViewTokenProcessor`.
enum ViewTokenEffect: Equatable {
    /// The view token screen appeared.
    case appeared

    /// The TOTP code for the view expired.
    case totpCodeExpired
}
