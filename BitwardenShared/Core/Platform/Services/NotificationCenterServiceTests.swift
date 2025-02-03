import XCTest

@testable import BitwardenShared

final class NotificationCenterServiceTests: BitwardenTestCase {
    // MARK: Properties

    var notificationCenter: NotificationCenter!
    var subject: DefaultNotificationCenterService!
    var didEnterBackgroundTask: Task<Void, Never>!
    var didEnterBackgroundPublished: Bool = false
    var willEnterForegroundTask: Task<Void, Never>!
    var willEnterBackgroundPublished: Bool = false

    // MARK: Setup & Teardown

    override func setUp() {
        notificationCenter = NotificationCenter()
        subject = DefaultNotificationCenterService(notificationCenter: notificationCenter)

        didEnterBackgroundTask = Task {
            for await _ in subject.didEnterBackgroundPublisher() {
                didEnterBackgroundPublished = true
            }
        }

        willEnterForegroundTask = Task {
            for await _ in subject.willEnterForegroundPublisher() {
                willEnterBackgroundPublished = true
            }
        }
    }

    override func tearDown() {
        didEnterBackgroundPublished = false
        didEnterBackgroundTask?.cancel()
        didEnterBackgroundTask = nil

        willEnterBackgroundPublished = false
        willEnterForegroundTask?.cancel()
        willEnterForegroundTask = nil

        notificationCenter = nil
        subject = nil
    }

    // MARK: Tests

    /// `didEnterBackgroundPublisher` publishes a notification when the app enters the background.
    func test_didEnterBackgroundPublisher() async throws {
        try await waitForAsync { [weak self] in
            let task = Task {
                self?.notificationCenter.post(
                    name: UIApplication.didEnterBackgroundNotification,
                    object: nil
                )
            }
            defer { task.cancel() }
            return self?.didEnterBackgroundPublished == true
        }
    }

    /// `willEnterForegroundPublisher` publishes a notification when the app will enter the foreground.
    func test_willEnterForegroundPublisher() async throws {
        try await waitForAsync { [weak self] in
            let task = Task {
                self?.notificationCenter.post(
                    name: UIApplication.willEnterForegroundNotification,
                    object: nil
                )
            }
            defer { task.cancel() }
            return self?.willEnterBackgroundPublished == true
        }
    }
}
