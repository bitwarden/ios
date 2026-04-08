import BitwardenKit
import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - ASSettingsMediatorTests

@MainActor
struct ASSettingsMediatorTests {
    // MARK: Properties

    var asSettingsHelperProxy: MockASSettingsHelperProxy
    var stateService: MockStateService
    var timeProvider: MockTimeProvider
    var subject: DefaultASSettingsMediator

    // MARK: Initialization

    init() {
        asSettingsHelperProxy = MockASSettingsHelperProxy()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1)))
        subject = DefaultASSettingsMediator(
            asSettingsHelperProxy: asSettingsHelperProxy,
            stateService: stateService,
            timeProvider: timeProvider,
        )
    }

    // MARK: openVerificationCodeAppSettings Tests

    /// `openVerificationCodeAppSettings()` delegates to the proxy.
    @Test
    @available(iOS 17, *)
    func openVerificationCodeAppSettings_delegates() async throws {
        try await subject.openVerificationCodeAppSettings()

        #expect(asSettingsHelperProxy.openVerificationCodeAppSettingsCalled)
    }

    /// `openVerificationCodeAppSettings()` rethrows errors from the proxy.
    @Test
    @available(iOS 17, *)
    func openVerificationCodeAppSettings_rethrowsError() async {
        asSettingsHelperProxy.openVerificationCodeAppSettingsThrowableError = BitwardenTestError.example

        await #expect(throws: BitwardenTestError.example) {
            try await subject.openVerificationCodeAppSettings()
        }
    }

    // MARK: requestToTurnOnCredentialProviderExtension Tests

    /// `requestToTurnOnCredentialProviderExtension()` throws ``ASSettingsMediatorError/cantRequest``
    /// when the wait time has not elapsed since the last request.
    @Test
    @available(iOS 18, *)
    func requestToTurnOnCredentialProviderExtension_cantRequest() async {
        stateService.lastRequestToTurnOnCredentialProvider = timeProvider.presentTime

        await #expect(throws: ASSettingsMediatorError.cantRequest) {
            try await subject.requestToTurnOnCredentialProviderExtension()
        }
        // State should not be updated when we couldn't make the request.
        #expect(stateService.lastRequestToTurnOnCredentialProvider == timeProvider.presentTime)
    }

    /// `requestToTurnOnCredentialProviderExtension()` can make a request when no prior request exists.
    @Test
    @available(iOS 18, *)
    func requestToTurnOnCredentialProviderExtension_canRequestWhenNoPriorRequest() async throws {
        #expect(stateService.lastRequestToTurnOnCredentialProvider == nil)

        asSettingsHelperProxy.requestToTurnOnCredentialProviderExtensionReturnValue = true

        _ = try await subject.requestToTurnOnCredentialProviderExtension()

        #expect(asSettingsHelperProxy.requestToTurnOnCredentialProviderExtensionCalled)
    }

    /// `requestToTurnOnCredentialProviderExtension()` can make a request when the wait time
    /// has elapsed since the last request.
    @Test
    @available(iOS 18, *)
    func requestToTurnOnCredentialProviderExtension_canRequestAfterWaitTime() async throws {
        let pastDate = timeProvider.presentTime.addingTimeInterval(
            -(Constants.requestToTurnOnCredentialProviderExtensionWaitTime + 1),
        )
        stateService.lastRequestToTurnOnCredentialProvider = pastDate

        asSettingsHelperProxy.requestToTurnOnCredentialProviderExtensionReturnValue = true

        _ = try await subject.requestToTurnOnCredentialProviderExtension()

        #expect(asSettingsHelperProxy.requestToTurnOnCredentialProviderExtensionCalled)
    }

    /// `requestToTurnOnCredentialProviderExtension()` returns `true` when the proxy reports
    /// the credential provider is enabled.
    @Test
    @available(iOS 18, *)
    func requestToTurnOnCredentialProviderExtension_returnsTrue() async throws {
        asSettingsHelperProxy.requestToTurnOnCredentialProviderExtensionReturnValue = true

        let result = try await subject.requestToTurnOnCredentialProviderExtension()

        #expect(result == true)
    }

    /// `requestToTurnOnCredentialProviderExtension()` returns `false` when the proxy reports
    /// the credential provider is disabled.
    @Test
    @available(iOS 18, *)
    func requestToTurnOnCredentialProviderExtension_returnsFalse() async throws {
        asSettingsHelperProxy.requestToTurnOnCredentialProviderExtensionReturnValue = false

        let result = try await subject.requestToTurnOnCredentialProviderExtension()

        #expect(result == false)
    }

    /// `requestToTurnOnCredentialProviderExtension()` saves the current time as the last request date
    /// after a successful request.
    @Test
    @available(iOS 18, *)
    func requestToTurnOnCredentialProviderExtension_savesRequestTimestamp() async throws {
        asSettingsHelperProxy.requestToTurnOnCredentialProviderExtensionReturnValue = true

        _ = try await subject.requestToTurnOnCredentialProviderExtension()

        #expect(stateService.lastRequestToTurnOnCredentialProvider == timeProvider.presentTime)
    }
}
