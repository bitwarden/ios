import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - ServiceContainerTests

class ServiceContainerTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(appContext:errorReporter:)` sets the app context to "App Extension" on the error reporter.
    @MainActor
    func test_init_setsAppContext_appExtension() {
        let errorReporter = MockErrorReporter()
        _ = ServiceContainer(appContext: .appExtension, errorReporter: errorReporter)
        XCTAssertEqual(errorReporter.appContext, "App Extension")
    }

    /// `init(appContext:errorReporter:)` sets the app context to "Main App" on the error reporter.
    @MainActor
    func test_init_setsAppContext_mainApp() {
        let errorReporter = MockErrorReporter()
        _ = ServiceContainer(appContext: .mainApp, errorReporter: errorReporter)
        XCTAssertEqual(errorReporter.appContext, "Main App")
    }
}
