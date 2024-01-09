/// A model to provide time for a TOTP code expiration check
///
struct TOTPTime {
    /// A time provider for marking the present time.
    ///
    var provider: any TimeProvider

    /// Initializes the model
    ///
    /// - Parameter provider: The TimeProvider for the model.
    ///
    init(provider: any TimeProvider) {
        self.provider = provider
    }
}

extension TOTPTime: Equatable {
    static func == (
        lhs: TOTPTime,
        rhs: TOTPTime
    ) -> Bool {
        true
    }
}

extension TOTPTime {
    /// A time provider that always returns the present time.
    ///
    static var currentTime: TOTPTime {
        TOTPTime(provider: CurrentTime())
    }
}
