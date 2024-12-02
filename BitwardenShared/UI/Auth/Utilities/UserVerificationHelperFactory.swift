/// A factory protocol to create `UserVerificationHelper`s.
protocol UserVerificationHelperFactory {
    func create() -> UserVerificationHelper
}

/// The default implemenetation for `UserVerificationHelperFactory`.
struct DefaultUserVerificationHelperFactory: UserVerificationHelperFactory {
    // MARK: Properties

    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The service used by the application to evaluate local auth policies.
    let localAuthService: LocalAuthService

    // MARK: Initialization

    /// Initialize a `DefaultUserVerificationHelper`.
    /// - Parameters:
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - localAuthService:  The service used by the application to evaluate local auth policies.
    init(authRepository: AuthRepository,
         errorReporter: ErrorReporter,
         localAuthService: LocalAuthService
    ) {
        self.authRepository = authRepository
        self.errorReporter = errorReporter
        self.localAuthService = localAuthService
    }

    // MARK: Methods

    func create() -> UserVerificationHelper {
        DefaultUserVerificationHelper(
            authRepository: authRepository,
            errorReporter: errorReporter,
            localAuthService: localAuthService
        )
    }
}
