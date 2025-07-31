/// Factory to create `CipherMatchingHelper`.
protocol CipherMatchingHelperFactory { // sourcery: AutoMockable
    /// Makes a `CipherMatchingHelper` from a given `uri`.
    /// - Parameter uri: The URI to initialize the helper with.
    /// - Returns: A new instance of a `CipherMatchingHelper`.
    func make(uri: String) async -> CipherMatchingHelper
}

/// Default `CipherMatchingHelperFactory` to create `CipherMatchingHelper`.
struct DefaultCipherMatchingHelperFactory: CipherMatchingHelperFactory {
    // MARK: Properties

    /// The service used by the application to manage user settings.
    let settingsService: SettingsService

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The cipher matching helper to use in tests to be able to mock it.
    let testCipherMatchingHelper: CipherMatchingHelper?

    init(
        settingsService: SettingsService,
        stateService: StateService,
        testCipherMatchingHelper: CipherMatchingHelper? = nil
    ) {
        self.settingsService = settingsService
        self.stateService = stateService
        self.testCipherMatchingHelper = testCipherMatchingHelper
    }

    // MARK: Methods

    func make(uri: String) async -> CipherMatchingHelper {
        let helper = testCipherMatchingHelper ?? DefaultCipherMatchingHelper(
            settingsService: settingsService,
            stateService: stateService
        )
        await helper.prepare(uri: uri)
        return helper
    }
}
