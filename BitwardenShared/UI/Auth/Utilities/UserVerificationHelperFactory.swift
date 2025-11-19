import BitwardenKit

/// A factory protocol to create `UserVerificationHelper`s.
protocol UserVerificationHelperFactory {
    func create() -> UserVerificationHelper
}

/// The default implementation for `UserVerificationHelperFactory`.
struct DefaultUserVerificationHelperFactory: UserVerificationHelperFactory {
    // MARK: Properties

    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The service used by the application to evaluate local auth policies.
    let localAuthService: LocalAuthService

    // MARK: Methods

    func create() -> UserVerificationHelper {
        DefaultUserVerificationHelper(
            authRepository: authRepository,
            errorReporter: errorReporter,
            localAuthService: localAuthService,
        )
    }
}
