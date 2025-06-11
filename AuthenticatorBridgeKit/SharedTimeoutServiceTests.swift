import AuthenticatorBridgeKit
import AuthenticatorBridgeKitMocks
import BitwardenKit
import BitwardenKitMocks
import XCTest

final class SharedTimeoutServiceTests: BitwardenTestCase {
    // MARK: Properties

    var sharedKeychainRepository: MockSharedKeychainRepository!
    var subject: SharedTimeoutService!
    var timeProvider: MockTimeProvider!

    // MARK: Set up & Tear down

    override func setUp() {
        super.setUp()

        sharedKeychainRepository = MockSharedKeychainRepository()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 6, day: 20)))

        self.subject = DefaultSharedTimeoutService(
            sharedKeychainRepository: sharedKeychainRepository,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        sharedKeychainRepository = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `clearTimeout(userId:)` clears the timeout for a user
    func test_clearTimeout() async throws {
        sharedKeychainRepository.accountAutoLogoutTime["1"] = timeProvider.presentTime
        try await subject.clearTimeout(forUserId: "1")
        XCTAssertNil(sharedKeychainRepository.accountAutoLogoutTime["1"])
    }

    /// `hasPassedTimeout` uses the current time to determine if the timeout has passed.
    /// If the current time is the timeout, then it is considered passed.
    func test_hasPassedTimeout() async throws {
        sharedKeychainRepository.accountAutoLogoutTime["1"] = timeProvider.presentTime.addingTimeInterval(-1)
        var value = try await subject.hasPassedTimeout(userId: "1")
        XCTAssertTrue(value)

        sharedKeychainRepository.accountAutoLogoutTime["1"] = timeProvider.presentTime
        value = try await subject.hasPassedTimeout(userId: "1")
        XCTAssertTrue(value)

        sharedKeychainRepository.accountAutoLogoutTime["1"] = timeProvider.presentTime.addingTimeInterval(1)
        value = try await subject.hasPassedTimeout(userId: "1")
        XCTAssertFalse(value)
    }

    /// `hasPassedTimeout` returns false if there is no timeout
    func test_hasPassedTimeout_noTimeout() async throws {
        let value = try await subject.hasPassedTimeout(userId: "1")
        XCTAssertFalse(value)
    }

    /// `updateTimeout(:::)` updates the timeout accordingly
    func test_updateTimeout() async throws {
        try await subject.updateTimeout(
            forUserId: "1",
            lastActiveDate: timeProvider.presentTime,
            timeoutLength: .fourHours
        )
        XCTAssertEqual(
            sharedKeychainRepository.accountAutoLogoutTime["1"],
            timeProvider.presentTime.addingTimeInterval(TimeInterval(SessionTimeoutValue.fourHours.seconds))
        )
    }

    /// `updateTimeout(:::)` clears the timeout if the date is nil
    func test_updateTimeout_nil() async throws {
        sharedKeychainRepository.accountAutoLogoutTime["1"] = timeProvider.presentTime
        try await subject.updateTimeout(forUserId: "1", lastActiveDate: nil, timeoutLength: .fourHours)
        XCTAssertNil(sharedKeychainRepository.accountAutoLogoutTime["1"])
    }
}
