import SwiftUI
import XCTest

@testable import BitwardenShared

class TabNavigatorTests: BitwardenTestCase {
    // MARK: Types

    enum TestRoute: Int, Equatable, Hashable, TabRepresentable {
        case firstTab
        case secondTab
        case thirdTab

        static var firstTabImage = UIImage(systemName: "scribble.variable")
        static var firstTabSelectedImage = UIImage(systemName: "externaldrive.fill.badge.wifi")
        static var secondTabImage = UIImage(systemName: "doc.richtext.fill.ja")
        static var secondTabSelectedImage = UIImage(systemName: "lanyardcard.fill")
        static var thirdTabImage = UIImage(systemName: "figure.curling")
        static var thirdTabSelectedImage = UIImage(systemName: "medal.fill")

        var image: UIImage? {
            switch self {
            case .firstTab: return Self.firstTabImage
            case .secondTab: return Self.secondTabImage
            case .thirdTab: return Self.thirdTabImage
            }
        }

        var selectedImage: UIImage? {
            switch self {
            case .firstTab: return Self.firstTabSelectedImage
            case .secondTab: return Self.secondTabSelectedImage
            case .thirdTab: return Self.thirdTabSelectedImage
            }
        }

        var title: String {
            switch self {
            case .firstTab: return "first"
            case .secondTab: return "second"
            case .thirdTab: return "third"
            }
        }
    }

    // MARK: Properties

    var subject: UITabBarController!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = UITabBarController()
        setKeyWindowRoot(viewController: subject)
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `isPresenting` returns true when a view is being presented on this navigator.
    @MainActor
    func test_isPresenting() {
        XCTAssertFalse(subject.isPresenting)

        subject.present(UIViewController(), animated: false)
        XCTAssertTrue(subject.isPresenting)
    }

    /// `rootViewController` returns itself.
    @MainActor
    func test_rootViewController() {
        XCTAssertIdentical(subject.rootViewController, subject)
    }

    /// `navigatorFor` with `.firstTab` returns the correct view controller.
    @MainActor
    func test_navigatorFor_firstTab() {
        let viewController = UINavigationController()
        subject.viewControllers = [viewController]

        let testController = subject.navigator(for: TestRoute.firstTab)
        XCTAssertIdentical(testController, viewController)
    }

    /// `setNavigators` sets the `viewControllers` property correctly.
    @MainActor
    func test_setNavigators() throws {
        // Setup
        let firstTabViewController = UIViewController()
        let secondTabViewController = UIViewController()
        let thirdTabViewController = UIViewController()

        let tabs: [TestRoute: MockRootNavigator] = [
            .thirdTab: MockRootNavigator(),
            .firstTab: MockRootNavigator(),
            .secondTab: MockRootNavigator(),
        ]
        tabs[.firstTab]?.rootViewController = firstTabViewController
        tabs[.secondTab]?.rootViewController = secondTabViewController
        tabs[.thirdTab]?.rootViewController = thirdTabViewController

        // Test case
        subject.setNavigators(tabs)

        // Assertions
        XCTAssertEqual(subject.viewControllers?.count, 3)

        let firstTab = try XCTUnwrap(subject.viewControllers?[0])
        XCTAssertIdentical(firstTab, firstTabViewController)
        XCTAssertEqual(firstTab.tabBarItem.title, "first")
        XCTAssertEqual(firstTab.tabBarItem.image?.pngData(), TestRoute.firstTabImage?.pngData())
        XCTAssertEqual(firstTab.tabBarItem.selectedImage?.pngData(), TestRoute.firstTabSelectedImage?.pngData())

        let secondTab = try XCTUnwrap(subject.viewControllers?[1])
        XCTAssertIdentical(secondTab, secondTabViewController)
        XCTAssertEqual(secondTab.tabBarItem.title, "second")
        XCTAssertEqual(secondTab.tabBarItem.image?.pngData(), TestRoute.secondTabImage?.pngData())
        XCTAssertEqual(secondTab.tabBarItem.selectedImage?.pngData(), TestRoute.secondTabSelectedImage?.pngData())

        let thirdTab = try XCTUnwrap(subject.viewControllers?[2])
        XCTAssertIdentical(thirdTab, thirdTabViewController)
        XCTAssertEqual(thirdTab.tabBarItem.title, "third")
        XCTAssertEqual(thirdTab.tabBarItem.image?.pngData(), TestRoute.thirdTabImage?.pngData())
        XCTAssertEqual(thirdTab.tabBarItem.selectedImage?.pngData(), TestRoute.thirdTabSelectedImage?.pngData())
    }
}
