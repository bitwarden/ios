import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - ASSettingsHelperProxyTests

@MainActor
struct ASSettingsHelperProxyTests {
    // MARK: Properties

    var stateService: MockStateService
    var timeProvider: MockTimeProvider
    var subject: DefaultASSettingsHelperProxy

    // MARK: Initialization

    init() {
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1)))
        subject = DefaultASSettingsHelperProxy(
            stateService: stateService,
            timeProvider: timeProvider,
        )
    }

    // MARK: Tests

    /// `requestToTurnOnCredentialProviderExtension()` returns `.cantRequest` when the wait time
    /// has not elapsed since the last request.
    @Test
    @available(iOS 18, *)
    func requestToTurnOnCredentialProviderExtension_cantRequest() async {
        // Set the last request date to the present time, so the wait time has not elapsed.
        stateService.lastRequestToTurnOnCredentialProvider = timeProvider.presentTime

        let result = await subject.requestToTurnOnCredentialProviderExtension()

        guard case .cantRequest = result else {
            Issue.record("Expected .cantRequest but got \(result)")
            return
        }
        // State should not be updated when we couldn't make the request.
        #expect(stateService.lastRequestToTurnOnCredentialProvider == timeProvider.presentTime)
    }

    /// `requestToTurnOnCredentialProviderExtension()` can make a request when no prior request exists.
    @Test
    @available(iOS 18, *)
    func requestToTurnOnCredentialProviderExtension_canRequestWhenNoPriorRequest() async {
        // No prior request date means `canRequest` should be true.
        #expect(stateService.lastRequestToTurnOnCredentialProvider == nil)

        // We can't call the actual ASSettingsHelper API in unit tests, but we can verify
        // the proxy saves the timestamp after a successful request attempt. Since the
        // system API will fail in a test environment, we only verify the `.cantRequest`
        // branch is not taken.
        let result = await subject.requestToTurnOnCredentialProviderExtension()

        // A result other than `.cantRequest` means the request was attempted.
        if case .cantRequest = result {
            Issue.record("Should have attempted a request since there's no prior request date")
        }
    }

    /// `requestToTurnOnCredentialProviderExtension()` can make a request when the wait time
    /// has elapsed since the last request.
    @Test
    @available(iOS 18, *)
    func requestToTurnOnCredentialProviderExtension_canRequestAfterWaitTime() async {
        // Set the last request date to beyond the wait time in the past.
        let pastDate = timeProvider.presentTime.addingTimeInterval(
            -(Constants.requestToTurnOnCredentialProviderExtensionWaitTime + 1),
        )
        stateService.lastRequestToTurnOnCredentialProvider = pastDate

        let result = await subject.requestToTurnOnCredentialProviderExtension()

        // A result other than `.cantRequest` means the request was attempted.
        if case .cantRequest = result {
            Issue.record("Should have attempted a request since the wait time has elapsed")
        }
    }
}
