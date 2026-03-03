import Testing

@testable import BitwardenShared

// MARK: - AppContextTests

class AppContextTests {
    // MARK: Tests

    /// `appContextName` returns the expected string for each `AppContext` case.
    @Test
    func appContextName() {
        #expect(AppContext.appExtension.appContextName == "App Extension")
        #expect(AppContext.mainApp.appContextName == "Main App")
    }
}
