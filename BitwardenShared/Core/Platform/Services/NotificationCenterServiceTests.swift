import XCTest

@testable import BitwardenShared

final class NotificationCenterServiceTests: BitwardenTestCase {
    // MARK: Properties

    var notificationCenter: NotificationCenter!
    var subject: DefaultNotificationCenterService!

    // MARK: Setup & Teardown

    override func setUp() {
        notificationCenter = NotificationCenter()
        subject = DefaultNotificationCenterService(notificationCenter: notificationCenter)
    }

    override func tearDown() {
        notificationCenter = nil
        subject = nil
    }

    // MARK: Tests

    /// `didEnterBackgroundPublisher` publishes a notification when the app enters the background.
    func testDidEnterBackgroundPublisher() async throws {
        var iterator = subject.didEnterBackgroundPublisher().makeAsyncIterator()
        Task {
            notificationCenter.post(
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
        }
        let result: Void? = await iterator.next()

        XCTAssertNotNil(result)
    }

    /// `willEnterForegroundPublisher` publishes a notification when the app will enter the foreground.
    func testWillEnterForegroundPublisher() async throws {
        var iterator = subject.willEnterForegroundPublisher().makeAsyncIterator()
        Task {
            notificationCenter.post(
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        }
        let result: Void? = await iterator.next()

        XCTAssertNotNil(result)
    }
}
