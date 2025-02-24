import TestHelpers
import XCTest

@testable import BitwardenShared

final class NotificationCenterServiceTests: BitwardenTestCase {
    // MARK: Properties

    var notificationCenter: NotificationCenter!
    var subject: DefaultNotificationCenterService!
    var didEnterBackgroundExpectation: XCTestExpectation?
    var didEnterBackgroundTask: Task<Void, Never>!
    var willEnterForegroundExpectation: XCTestExpectation?
    var willEnterForegroundTask: Task<Void, Never>!

    // MARK: Setup & Teardown

    override func setUp() {
        notificationCenter = NotificationCenter()
        subject = DefaultNotificationCenterService(notificationCenter: notificationCenter)

        let didEnterBackgroundTaskStarted = expectation(description: "didEnterBackground")
        didEnterBackgroundTask = Task {
            didEnterBackgroundTaskStarted.fulfill()
            for await _ in subject.didEnterBackgroundPublisher() {
                didEnterBackgroundExpectation?.fulfill()
            }
        }

        let willEnterForegroundTaskStarted = expectation(description: "willEnterForeground")
        willEnterForegroundTask = Task {
            willEnterForegroundTaskStarted.fulfill()
            for await _ in subject.willEnterForegroundPublisher() {
                willEnterForegroundExpectation?.fulfill()
            }
        }

        wait(for: [didEnterBackgroundTaskStarted, willEnterForegroundTaskStarted])
    }

    override func tearDown() {
        didEnterBackgroundExpectation = nil
        didEnterBackgroundTask?.cancel()
        didEnterBackgroundTask = nil

        willEnterForegroundExpectation = nil
        willEnterForegroundTask?.cancel()
        willEnterForegroundTask = nil

        notificationCenter = nil
        subject = nil
    }

    // MARK: Tests

    /// `didEnterBackgroundPublisher` publishes a notification when the app enters the background.
    @MainActor
    func test_didEnterBackgroundPublisher() async throws {
        let expectation = expectation(description: #function)
        didEnterBackgroundExpectation = expectation

        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        await fulfillment(of: [expectation], timeout: 1)
    }

    /// `willEnterForegroundPublisher` publishes a notification when the app will enter the foreground.
    @MainActor
    func test_willEnterForegroundPublisher() async throws {
        let expectation = expectation(description: #function)
        willEnterForegroundExpectation = expectation

        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        await fulfillment(of: [expectation], timeout: 1)
    }
}
