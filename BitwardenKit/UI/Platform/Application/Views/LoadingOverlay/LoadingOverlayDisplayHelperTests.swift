import BitwardenKit
import SwiftUI
import XCTest

class LoadingOverlayDisplayHelperTests: BitwardenTestCase {
    /// `show(in:state:)` shows the loading overlay in the parent view controller.
    @MainActor
    func test_show() throws {
        let parentViewController = UIViewController()
        let window = UIWindow()
        window.rootViewController = parentViewController
        window.makeKeyAndVisible()

        LoadingOverlayDisplayHelper.show(
            in: parentViewController,
            state: LoadingOverlayState(title: "Loading..."),
        )

        let overlayView = try XCTUnwrap(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
        XCTAssertEqual(overlayView.layer.opacity, 1)
        guard #unavailable(iOS 26) else {
            return
        }
        XCTAssertNil(overlayView.layer.backgroundColor)
    }

    /// `hide(from:)` hides the loading overlay in the parent view controller.
    @MainActor
    func test_hide() throws {
        let parentViewController = UIViewController()
        let window = UIWindow()
        window.rootViewController = parentViewController
        window.makeKeyAndVisible()

        LoadingOverlayDisplayHelper.show(
            in: parentViewController,
            state: LoadingOverlayState(title: "Loading..."),
        )
        let overlayView = try XCTUnwrap(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        LoadingOverlayDisplayHelper.hide(from: parentViewController)

        waitFor { overlayView.superview == nil }

        XCTAssertNil(overlayView.superview)
        XCTAssertEqual(overlayView.layer.opacity, 0)
    }
}
