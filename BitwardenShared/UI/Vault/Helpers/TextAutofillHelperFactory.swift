/// Protocol to provide a factory to create `TextAutofillHelperFactory`.
protocol TextAutofillHelperFactory {
    /// Creates an instance of `TextAutofillHelperFactory`.
    func create() -> TextAutofillHelper
}

/// Default implemenation of `TextAutofillHelperFactory`.
struct DefaultTextAutofillHelperFactory: TextAutofillHelperFactory {
    // MARK: Properties

    /// The repository used by the application to manage auth data for the UI layer.
    private let authRepository: AuthRepository

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to record and send events.
    private let eventService: EventService

    /// A factory to create `UserVerificationHelper`s.
    private let userVerificationHelperFactory: UserVerificationHelperFactory

    /// The repository used by the application to manage vault data for the UI layer.
    private let vaultRepository: VaultRepository

    // MARK: Initialization

    /// Initialize an `DefaultTextAutofillHelper`.
    ///
    /// - Parameters:
    ///   - authRepository: A delegate used to communicate with the autofill app extension.
    ///   - errorReporter: The coordinator that handles navigation.
    ///   - eventService: The services used by this processor.
    ///   - userVerificationHelperFactory:A factory to create `UserVerificationHelper`s.
    ///   - vaultRepository: The repository used by the application to manage vault data for the UI layer.
    ///
    init(
        authRepository: AuthRepository,
        errorReporter: ErrorReporter,
        eventService: EventService,
        userVerificationHelperFactory: UserVerificationHelperFactory,
        vaultRepository: VaultRepository
    ) {
        self.authRepository = authRepository
        self.errorReporter = errorReporter
        self.eventService = eventService
        self.userVerificationHelperFactory = userVerificationHelperFactory
        self.vaultRepository = vaultRepository
    }

    // MARK: Methods

    func create() -> TextAutofillHelper {
        if #available(iOS 18.0, *) {
            DefaultTextAutofillHelper(
                authRepository: authRepository,
                errorReporter: errorReporter,
                eventService: eventService,
                userVerificationHelper: userVerificationHelperFactory.create(),
                vaultRepository: vaultRepository
            )
        } else {
            NoOpTextAutofillHelper()
        }
    }
}
