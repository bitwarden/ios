import XCTest

@testable import AuthenticatorShared

final class ConfigServiceTests: AuthenticatorTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var now: Date!
    var subject: DefaultConfigService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        subject = DefaultConfigService(
            errorReporter: errorReporter
        )
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `getFeatureFlag(:)` returns the default value for booleans
    func test_getFeatureFlag_bool_fallback() async {
        let value = await subject.getFeatureFlag(.testRemoteFlag, defaultValue: false, forceRefresh: false)
        XCTAssertFalse(value)
    }

    /// `getFeatureFlag(:)` returns the default local value for booleans if it is configured.
    func test_getFeatureFlag_bool_locallyConfigured() async {
        let value = await subject.getFeatureFlag(.testLocalBoolFlag, defaultValue: false, forceRefresh: false)
        XCTAssertTrue(value)
    }

    /// `getFeatureFlag(:)` returns the default value for integers
    func test_getFeatureFlag_int_fallback() async {
        let value = await subject.getFeatureFlag(.testRemoteFlag, defaultValue: 10, forceRefresh: false)
        XCTAssertEqual(value, 10)
    }

    /// `getFeatureFlag(:)` returns the default local value for integers if it is configured.
    func test_getFeatureFlag_int_locallyConfigured() async {
        let value = await subject.getFeatureFlag(.testLocalIntFlag, defaultValue: 10, forceRefresh: false)
        XCTAssertEqual(value, 42)
    }

    /// `getFeatureFlag(:)` returns the default value for strings
    func test_getFeatureFlag_string_fallback() async {
        let value = await subject.getFeatureFlag(.testRemoteFlag, defaultValue: "Default", forceRefresh: false)
        XCTAssertEqual(value, "Default")
    }

    /// `getFeatureFlag(:)` returns the default local value for integers if it is configured.
    func test_getFeatureFlag_string_locallyConfigured() async {
        let value = await subject.getFeatureFlag(.testLocalStringFlag, defaultValue: "Default", forceRefresh: false)
        XCTAssertEqual(value, "Test String")
    }
}
