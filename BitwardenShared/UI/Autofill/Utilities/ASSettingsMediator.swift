import AuthenticationServices
import BitwardenKit

// MARK: - ASSettingsMediatorError

/// An error thrown by ``ASSettingsMediator``.
///
enum ASSettingsMediatorError: Error {
    /// The request could not be made because the required wait time has not elapsed since the last request.
    case cantRequest
}

// MARK: - ASSettingsMediator

/// A mediator protocol for interacting with ``ASSettingsHelper`` with additional business logic.
///
protocol ASSettingsMediator { // sourcery: AutoMockable
    /// Calling this method will open the Settings app and navigate directly to the Verification Code provider settings.
    @available(iOS 17.0, *)
    func openVerificationCodeAppSettings() async throws

    /// Call this method from your containing app to request to turn on a contained Credential Provider Extension.
    /// If the extension is not currently enabled, a prompt will be shown to allow it to be turned on.
    ///
    /// Throws: ``ASSettingsMediatorError/cantRequest`` if the required wait time has
    /// not elapsed since the last request.
    /// Returns: whether the credential provider is enabled.
    @available(iOS 18.0, *)
    func requestToTurnOnCredentialProviderExtension() async throws -> Bool
}

/// Default implementation of ``ASSettingsMediator``.
///
class DefaultASSettingsMediator: ASSettingsMediator {
    // MARK: Properties

    /// The proxy used to make ``ASSettingsHelper`` calls.
    private let asSettingsHelperProxy: ASSettingsHelperProxy

    /// The service used to get and set state around autofill.
    private let stateService: AutofillStateService

    /// The provider used to get the current time.
    private let timeProvider: TimeProvider

    // MARK: Init

    /// Creates a new `DefaultASSettingsMediator`.
    ///
    /// - Parameters:
    ///   - asSettingsHelperProxy: The proxy used to make ``ASSettingsHelper`` calls.
    ///   - stateService: The service used to get and set state around autofill.
    ///   - timeProvider: The provider used to get the current time.
    init(
        asSettingsHelperProxy: ASSettingsHelperProxy,
        stateService: AutofillStateService,
        timeProvider: TimeProvider
    ) {
        self.asSettingsHelperProxy = asSettingsHelperProxy
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    @available(iOS 17.0, *)
    func openVerificationCodeAppSettings() async throws {
        try await asSettingsHelperProxy.openVerificationCodeAppSettings()
    }

    @available(iOS 18.0, *)
    func requestToTurnOnCredentialProviderExtension() async throws -> Bool {
        let lastRequestDate = await stateService.getLastRequestToTurnOnCredentialProvider()
        guard canRequestToTurnOnCredentialProviderExtension(lastRequestDate: lastRequestDate) else {
            throw ASSettingsMediatorError.cantRequest
        }

        let isOn = await asSettingsHelperProxy.requestToTurnOnCredentialProviderExtension()

        await stateService.setLastRequestToTurnOnCredentialProvider(timeProvider.presentTime)

        return isOn
    }

    // MARK: Private methods

    /// Returns whether a request to turn on the credential provider extension can be made.
    ///
    /// - Parameter lastRequestDate: The date of the last request, or `nil` if no prior request exists.
    /// - Returns: `true` if the required wait time since `lastRequestDate` has elapsed, `false` otherwise.
    private func canRequestToTurnOnCredentialProviderExtension(lastRequestDate: Date?) -> Bool {
        let requestTimeToCompare = lastRequestDate?.addingTimeInterval(
            Constants.requestToTurnOnCredentialProviderExtensionWaitTime,
        ) ?? .distantPast
        return requestTimeToCompare < timeProvider.presentTime
    }
}
