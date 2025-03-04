import SwiftUI
import XCTest

@testable import AuthenticatorShared

class LoadingOverlayDisplayHelperTests: AuthenticatorTestCase {
    /// `show(in:state:)` shows the loading overlay in the parent view controller.
    func test_show() throws {
        let parentViewController = UIViewController()
        let window = UIWindow()
        window.rootViewController = parentViewController
        window.makeKeyAndVisible()

        LoadingOverlayDisplayHelper.show(
            in: parentViewController,
            state: LoadingOverlayState(title: "Loading...")
        )

        let overlayView = try XCTUnwrap(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
        XCTAssertNil(overlayView.layer.backgroundColor)
        XCTAssertEqual(overlayView.layer.opacity, 1)
    }

    /// `hide(from:)` hides the loading overlay in the parent view controller.
    func test_hide() throws {
        let parentViewController = UIViewController()
        let window = UIWindow()
        window.rootViewController = parentViewController
        window.makeKeyAndVisible()

        LoadingOverlayDisplayHelper.show(
            in: parentViewController,
            state: LoadingOverlayState(title: "Loading...")
        )
        let overlayView = try XCTUnwrap(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        LoadingOverlayDisplayHelper.hide(from: parentViewController)

        waitFor { overlayView.superview == nil }

        XCTAssertNil(overlayView.superview)
        XCTAssertEqual(overlayView.layer.opacity, 0)
    }
}
