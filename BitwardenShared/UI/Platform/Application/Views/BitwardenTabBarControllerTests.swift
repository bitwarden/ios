import BitwardenKit
import BitwardenKitMocks
import SwiftUI
import Testing
import UIKit

@testable import BitwardenShared

@MainActor
struct BitwardenTabBarControllerTests {
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

    let subject: BitwardenTabBarController
    let window: UIWindow

    // MARK: Setup

    init() {
        window = UIWindow(frame: UIScreen.main.bounds)
        window.layer.speed = 100
        subject = BitwardenTabBarController()
        window.rootViewController = subject
        window.makeKeyAndVisible()
    }

    // MARK: Tests

    /// `isPresenting` returns true when a view is being presented on this navigator.
    @Test
    func isPresenting() {
        #expect(!subject.isPresenting)

        subject.present(UIViewController(), animated: false)
        #expect(subject.isPresenting)
    }

    /// `rootViewController` returns itself.
    @Test
    func rootViewController() {
        #expect(subject.rootViewController === subject)
    }

    /// `navigator(for:)` with `.firstTab` returns the correct view controller.
    @Test
    func navigatorFor_firstTab() {
        let viewController = UINavigationController()
        subject.viewControllers = [viewController]

        let testController = subject.navigator(for: TestRoute.firstTab)
        #expect(testController === viewController)
    }

    /// `navigator(for:)` with a `TabRoute` uses the stored dictionary and returns the correct
    /// navigator even when the Send tab is absent (non-contiguous indices).
    @Test
    func navigatorFor_tabRoute_sendHidden() {
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

        #expect(subject.navigator(for: TabRoute.generator(.generator())) === generatorNavigator)
        #expect(subject.navigator(for: TabRoute.settings(.settings(.tab))) === settingsNavigator)
        #expect(subject.navigator(for: TabRoute.send) == nil)
    }

    /// `navigator(for:)` matches by tab case and ignores associated values, returning the
    /// correct navigator even when the route carries a non-canonical associated value.
    @Test
    func navigatorFor_tabRoute_nonCanonicalAssociatedValue() {
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

        #expect(subject.navigator(for: TabRoute.generator(.generatorHistory)) === generatorNavigator)
        #expect(subject.navigator(for: TabRoute.vault(.addFolder)) === vaultNavigator)
        #expect(subject.navigator(for: TabRoute.settings(.about)) === settingsNavigator)
    }

    /// `setNavigators(_:)` sets the `viewControllers` property correctly.
    @Test
    func setNavigators() throws {
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

        subject.setNavigators(tabs)

        #expect(subject.viewControllers?.count == 3)

        let firstTab = try #require(subject.viewControllers?[0])
        #expect(firstTab === firstTabViewController)
        #expect(firstTab.tabBarItem.title == "first")
        #expect(firstTab.tabBarItem.image?.pngData() == TestRoute.firstTabImage?.pngData())
        #expect(firstTab.tabBarItem.selectedImage?.pngData() == TestRoute.firstTabSelectedImage?.pngData())

        let secondTab = try #require(subject.viewControllers?[1])
        #expect(secondTab === secondTabViewController)
        #expect(secondTab.tabBarItem.title == "second")
        #expect(secondTab.tabBarItem.image?.pngData() == TestRoute.secondTabImage?.pngData())
        #expect(secondTab.tabBarItem.selectedImage?.pngData() == TestRoute.secondTabSelectedImage?.pngData())

        let thirdTab = try #require(subject.viewControllers?[2])
        #expect(thirdTab === thirdTabViewController)
        #expect(thirdTab.tabBarItem.title == "third")
        #expect(thirdTab.tabBarItem.image?.pngData() == TestRoute.thirdTabImage?.pngData())
        #expect(thirdTab.tabBarItem.selectedImage?.pngData() == TestRoute.thirdTabSelectedImage?.pngData())
    }
}
