import BitwardenKit

/// Protocol for the service that controls the general state of the app.
protocol StateService {}

// MARK: - DefaultStateService

/// A default implementation of `StateService`.
///
actor DefaultStateService: StateService, ActiveAccountStateProvider {
    // MARK: Methods

    func getActiveAccountId() async throws -> String {
        "Test-Harness-Account-ID"
    }
}
