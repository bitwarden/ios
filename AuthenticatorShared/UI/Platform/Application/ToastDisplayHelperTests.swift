import SwiftUI
import XCTest

@testable import AuthenticatorShared

class ToastDisplayHelperTests: AuthenticatorTestCase {
    /// `show(in:state:)` shows the toast in the parent view controller.
    func test_show() throws {
        let parentViewController = UIViewController()
        let window = UIWindow()
        window.rootViewController = parentViewController
        window.makeKeyAndVisible()

        ToastDisplayHelper.show(
            in: parentViewController,
            toast: Toast(text: "With Butter")
        )

        let overlayView = try XCTUnwrap(window.viewWithTag(ToastDisplayHelper.toastTag))
        XCTAssertNil(overlayView.layer.backgroundColor)
        XCTAssertEqual(overlayView.layer.opacity, 1)
    }

    /// `hide(from:)` hides the toast from the parent view controller.
    func test_hide() throws {
        let parentViewController = UIViewController()
        let window = UIWindow()
        window.rootViewController = parentViewController
        window.makeKeyAndVisible()

        ToastDisplayHelper.show(
            in: parentViewController,
            toast: Toast(text: "With Butter"),
            duration: 0.1
        )
        let overlayView = try XCTUnwrap(window.viewWithTag(ToastDisplayHelper.toastTag))

        waitFor { overlayView.superview == nil }

        XCTAssertNil(overlayView.superview)
        XCTAssertEqual(overlayView.layer.opacity, 0)
    }
}
