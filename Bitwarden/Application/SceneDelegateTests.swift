import XCTest

@testable import Bitwarden
@testable import BitwardenShared

// MARK: - SceneDelegateTests

class SceneDelegateTests: BitwardenTestCase {
    // MARK: Properties

    var appModule: MockAppModule!
    var subject: SceneDelegate!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        appModule = MockAppModule()
        subject = SceneDelegate()
    }

    override func tearDown() {
        super.tearDown()
        appModule = nil
        subject = nil
    }

    // MARK: Tests

    /// `scene(_:willConnectTo:options:)` with a `UIWindowScene` creates the app's UI.
    func test_sceneWillConnectTo_withWindowScene() throws {
        let appProcessor = AppProcessor(appModule: appModule, services: ServiceContainer())
        (UIApplication.shared.delegate as? TestingAppDelegate)?.appProcessor = appProcessor

        let session = TestInstanceFactory.create(UISceneSession.self)
        let scene = TestInstanceFactory.create(UIWindowScene.self, properties: [
            "session": session,
        ])
        let options = TestInstanceFactory.create(UIScene.ConnectionOptions.self)
        subject.scene(scene, willConnectTo: session, options: options)

        XCTAssertNotNil(appProcessor.coordinator)
        XCTAssertNotNil(subject.window)
        XCTAssertTrue(appModule.appCoordinator.isStarted)
    }

    /// `scene(_:willConnectTo:options:)` without a `UIWindowScene` fails to create the app's UI.
    func test_sceneWillConnectTo_withNonWindowScene() throws {
        let appProcessor = AppProcessor(appModule: appModule, services: ServiceContainer())
        (UIApplication.shared.delegate as? TestingAppDelegate)?.appProcessor = appProcessor

        let session = TestInstanceFactory.create(UISceneSession.self)
        let scene = TestInstanceFactory.create(UIScene.self, properties: [
            "session": session,
        ])
        let options = TestInstanceFactory.create(UIScene.ConnectionOptions.self)
        subject.scene(scene, willConnectTo: session, options: options)

        XCTAssertNil(appProcessor.coordinator)
        XCTAssertNil(subject.window)
        XCTAssertFalse(appModule.appCoordinator.isStarted)
    }
}
