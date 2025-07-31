import XCTest

@testable import BitwardenShared

// MARK: - CipherMatchingHelperFactoryTests

class CipherMatchingHelperFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var cipherMatchingHelper: MockCipherMatchingHelper!
    var settingsService: MockSettingsService!
    var stateService: MockStateService!
    var subject: DefaultCipherMatchingHelperFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherMatchingHelper = MockCipherMatchingHelper()
        settingsService = MockSettingsService()
        stateService = MockStateService()
    }

    override func tearDown() {
        super.tearDown()

        cipherMatchingHelper = nil
        settingsService = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `make(uri:)` makes a `DefaultCipherMatchingHelper`.
    func test_make() async {
        subject = DefaultCipherMatchingHelperFactory(
            settingsService: settingsService,
            stateService: stateService
        )

        let result = await subject.make(uri: "https://example.com")
        XCTAssertTrue(result is DefaultCipherMatchingHelper)
    }

    /// `make(uri:)` makes a new `CipherMatchingHelper` and tests that
    /// `prepare(uri:)` gets called in the mocked helper.
    func test_make_withMock() async {
        subject = DefaultCipherMatchingHelperFactory(
            settingsService: settingsService,
            stateService: stateService,
            testCipherMatchingHelper: cipherMatchingHelper
        )

        let result = await subject.make(uri: "https://example.com")
        XCTAssertEqual(cipherMatchingHelper.prepareReceivedUri, "https://example.com")
        XCTAssertTrue(result is MockCipherMatchingHelper)
    }
}
