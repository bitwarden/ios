import AuthenticationServices
import BitwardenKit

// MARK: - CredentialProviderExtensionRequestResult

/// The result of requesting to turn on the credential provider extension.
enum CredentialProviderExtensionRequestResult {
    /// The request could not be made because the required wait time has not elapsed since the last request.
    case cantRequest

    /// The request was made. The associated `Bool` value indicates whether the credential provider is enabled.
    case requestResult(Bool)
}

/// A proxy protocol to call ``ASSettingsHelper`` functions so it can be mocked.
protocol ASSettingsHelperProxy { // sourcery: AutoMockable
    /// Calling this method will open the Settings app and navigate directly to the Verification Code provider settings.
    @available(iOS 17.0, *)
    func openVerificationCodeAppSettings() async throws

    /// Call this method from your containing app to request to turn on a contained Credential Provider Extension.
    /// If the extension is not currently enabled, a prompt will be shown to allow it to be turned on.
    /// Returns ``CredentialProviderExtensionRequestResult/cantRequest`` if the required wait time has not elapsed
    /// since the last request, or ``CredentialProviderExtensionRequestResult/turnedOn(_:)`` with whether the
    /// credential provider is enabled.
    @available(iOS 18.0, *)
    func requestToTurnOnCredentialProviderExtension() async -> CredentialProviderExtensionRequestResult
}

/// Default implementation of ``ASSettingsHelperProxy``.
class DefaultASSettingsHelperProxy: ASSettingsHelperProxy {
    // MARK: Properties

    /// The service used to get and set per-user state.
    private let stateService: StateService

    /// The provider used to get the current time.
    private let timeProvider: TimeProvider

    // MARK: Init

    /// Creates a new `DefaultASSettingsHelperProxy`.
    ///
    /// - Parameters:
    ///   - stateService: The service used to get and set per-user state.
    ///   - timeProvider: The provider used to get the current time.
    init(stateService: StateService, timeProvider: TimeProvider) {
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    @available(iOS 17.0, *)
    func openVerificationCodeAppSettings() async throws {
        try await ASSettingsHelper.openVerificationCodeAppSettings()
    }

    @available(iOS 18.0, *)
    func requestToTurnOnCredentialProviderExtension() async -> CredentialProviderExtensionRequestResult {
        let lastRequestDate = await stateService.getLastRequestToTurnOnCredentialProvider()
        guard canRequestToTurnOnCredentialProviderExtension(lastRequestDate: lastRequestDate) else {
            return .cantRequest
        }

        let isOn = await ASSettingsHelper.requestToTurnOnCredentialProviderExtension()

        await stateService.setLastRequestToTurnOnCredentialProvider(timeProvider.presentTime)

        return .requestResult(isOn)
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
