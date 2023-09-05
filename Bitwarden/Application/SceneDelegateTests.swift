import BitwardenShared
import XCTest

@testable import Bitwarden

// MARK: - SceneDelegateTests

class SceneDelegateTests: BitwardenTestCase {
    // MARK: Properties

    var appCoordinator: MockCoordinator<AppRoute>!
    var appModule: MockAppModule!
    var subject: SceneDelegate!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        appCoordinator = MockCoordinator<AppRoute>()
        appModule = MockAppModule()
        appModule.appCoordinator = appCoordinator.asAnyCoordinator()
        subject = SceneDelegate()
        subject.appModule = appModule
    }

    override func tearDown() {
        super.tearDown()
        appModule = nil
        subject = nil
    }

    // MARK: Tests

    /// `scene(_:willConnectTo:options:)` with a `UIWindowScene` creates the app's UI.
    func test_sceneWillConnectTo_withWindowScene() throws {
        let session = TestInstanceFactory.create(UISceneSession.self)
        let scene = TestInstanceFactory.create(UIWindowScene.self, properties: [
            "session": session,
        ])
        let options = TestInstanceFactory.create(UIScene.ConnectionOptions.self)
        subject.scene(scene, willConnectTo: session, options: options)

        XCTAssertNotNil(subject.appCoordinator)
        XCTAssertNotNil(subject.window)
        XCTAssertTrue(appCoordinator.isStarted)
    }

    /// `scene(_:willConnectTo:options:)` without a `UIWindowScene` fails to create the app's UI.
    func test_sceneWillConnectTo_withNonWindowScene() throws {
        let session = TestInstanceFactory.create(UISceneSession.self)
        let scene = TestInstanceFactory.create(UIScene.self, properties: [
            "session": session,
        ])
        let options = TestInstanceFactory.create(UIScene.ConnectionOptions.self)
        subject.scene(scene, willConnectTo: session, options: options)

        XCTAssertNil(subject.appCoordinator)
        XCTAssertNil(subject.window)
        XCTAssertFalse(appCoordinator.isStarted)
    }
}
