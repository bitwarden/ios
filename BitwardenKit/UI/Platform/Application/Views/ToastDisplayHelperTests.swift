import BitwardenKit
import SwiftUI
import TestHelpers
import XCTest

class ToastDisplayHelperTests: BitwardenTestCase {
    /// `show(in:state:)` shows the toast in the parent view controller.
    @MainActor
    func test_show() throws {
        let parentViewController = UIViewController()
        let window = UIWindow()
        window.rootViewController = parentViewController
        window.makeKeyAndVisible()

        ToastDisplayHelper.show(
            in: parentViewController,
            toast: Toast(title: "With Butter"),
        )

        let overlayView = try XCTUnwrap(window.viewWithTag(ToastDisplayHelper.toastTag))
        XCTAssertEqual(overlayView.layer.opacity, 1)
        guard #unavailable(iOS 26) else {
            return
        }
        XCTAssertNil(overlayView.layer.backgroundColor)
    }

    /// `hide(from:)` hides the toast from the parent view controller.
    @MainActor
    func test_hide() throws {
        let parentViewController = UIViewController()
        let window = UIWindow()
        window.rootViewController = parentViewController
        window.makeKeyAndVisible()

        ToastDisplayHelper.show(
            in: parentViewController,
            toast: Toast(title: "With Butter"),
            duration: 0.1,
        )
        let overlayView = try XCTUnwrap(window.viewWithTag(ToastDisplayHelper.toastTag))

        waitFor { overlayView.superview == nil }

        XCTAssertNil(overlayView.superview)
        XCTAssertEqual(overlayView.layer.opacity, 0)
    }
}
