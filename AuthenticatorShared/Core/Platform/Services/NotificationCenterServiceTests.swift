import XCTest

@testable import AuthenticatorShared

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
    func testDidEnterBackgroundPublisher() {
        let expectation = XCTestExpectation(description: "Application entered background")
        let cancellable = subject.didEnterBackgroundPublisher()
            .sink { _ in
                expectation.fulfill()
            }

        notificationCenter.post(
            name: UIApplication.didEnterBackgroundNotification,
            object: nil,
        )

        wait(for: [expectation], timeout: 1)
        cancellable.cancel()
    }

    /// `willEnterForegroundPublisher` publishes a notification when the app will enter the foreground.
    func testWillEnterForegroundPublisher() {
        let expectation = XCTestExpectation(description: "Application will enter foreground")
        let cancellable = subject.willEnterForegroundPublisher()
            .sink { _ in
                expectation.fulfill()
            }

        notificationCenter.post(
            name: UIApplication.willEnterForegroundNotification,
            object: nil,
        )

        wait(for: [expectation], timeout: 1)
        cancellable.cancel()
    }
}
