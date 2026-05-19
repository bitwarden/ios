import BitwardenKit
import BitwardenKitMocks
import SwiftUI
import XCTest

@testable import BitwardenShared

class BitwardenTabBarControllerTests: BitwardenTestCase {
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
            case .firstTab:
                Self.firstTabImage
            case .secondTab:
                Self.secondTabImage
            case .thirdTab:
                Self.thirdTabImage
            }
        }

        var selectedImage: UIImage? {
            switch self {
            case .firstTab:
                Self.firstTabSelectedImage
            case .secondTab:
                Self.secondTabSelectedImage
            case .thirdTab:
                Self.thirdTabSelectedImage
            }
        }

        var title: String {
            switch self {
            case .firstTab:
                "first"
            case .secondTab:
                "second"
            case .thirdTab:
                "third"
            }
        }
    }

    // MARK: Properties

    var subject: BitwardenTabBarController!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = BitwardenTabBarController()
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

    /// `navigator(for:)` with a `TabRoute` uses the stored dictionary and returns the correct
    /// navigator even when the Send tab is absent (non-contiguous indices).
    @MainActor
    func test_navigatorFor_tabRoute_sendHidden() throws {
        let vaultNavigator = MockRootNavigator()
        let generatorNavigator = MockRootNavigator()
        let settingsNavigator = MockRootNavigator()
        vaultNavigator.rootViewController = UIViewController()
        generatorNavigator.rootViewController = UIViewController()
        settingsNavigator.rootViewController = UIViewController()

        let tabs: [TabRoute: MockRootNavigator] = [
            .vault(.list): vaultNavigator,
            .generator(.generator()): generatorNavigator,
            .settings(.settings(.tab)): settingsNavigator,
        ]
        subject.setNavigators(tabs)

        XCTAssertIdentical(
            subject.navigator(for: TabRoute.generator(.generator())),
            generatorNavigator,
        )
        XCTAssertIdentical(
            subject.navigator(for: TabRoute.settings(.settings(.tab))),
            settingsNavigator,
        )
        XCTAssertNil(subject.navigator(for: TabRoute.send))
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
