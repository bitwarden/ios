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

    /// `isInForegroundPublisher` initially emits `false`.
    @MainActor
    func test_isInForegroundPublisher_initialValue() async throws {
        let expectation = expectation(description: #function)
        var received: Bool?
        let task = Task {
            for await value in subject.isInForegroundPublisher() {
                received = value
                expectation.fulfill()
                break
            }
        }
        await fulfillment(of: [expectation], timeout: 1)
        task.cancel()
        XCTAssertEqual(received, false)
    }

    /// `isInForegroundPublisher` emits `false` when the app enters the background.
    @MainActor
    func test_isInForegroundPublisher_didEnterBackground() async throws {
        let receivedInitial = expectation(description: "receivedInitial")
        let receivedBackground = expectation(description: "receivedBackground")
        var received: Bool?

        let task = Task {
            var isFirst = true
            for await value in subject.isInForegroundPublisher() {
                if isFirst {
                    isFirst = false
                    receivedInitial.fulfill()
                    continue
                }
                received = value
                receivedBackground.fulfill()
                break
            }
        }

        await fulfillment(of: [receivedInitial], timeout: 1)
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        await fulfillment(of: [receivedBackground], timeout: 1)
        task.cancel()

        XCTAssertEqual(received, false)
    }

    /// `isInForegroundPublisher` emits `true` when the app returns to the foreground.
    @MainActor
    func test_isInForegroundPublisher_willEnterForeground() async throws {
        let receivedInitial = expectation(description: "receivedInitial")
        let receivedBackground = expectation(description: "receivedBackground")
        let receivedForeground = expectation(description: "receivedForeground")
        var received: Bool?

        let task = Task {
            var count = 0
            for await value in subject.isInForegroundPublisher() {
                count += 1
                if count == 1 { receivedInitial.fulfill(); continue }
                if count == 2 { receivedBackground.fulfill(); continue }
                received = value
                receivedForeground.fulfill()
                break
            }
        }

        await fulfillment(of: [receivedInitial], timeout: 1)
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        await fulfillment(of: [receivedBackground], timeout: 1)
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        await fulfillment(of: [receivedForeground], timeout: 1)
        task.cancel()

        XCTAssertEqual(received, true)
    }
}
