import Foundation
import XCTest

@testable import AuthenticatorShared

class AppProcessorTests: AuthenticatorTestCase {
    // MARK: Properties

    var appModule: MockAppModule!
    var coordinator: MockCoordinator<AppRoute, AppEvent>!
    var errorReporter: MockErrorReporter!
    var router: MockRouter<AuthEvent, AuthRoute>!
    var subject: AppProcessor!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        router = MockRouter(routeForEvent: { _ in .vaultUnlock })
        appModule = MockAppModule()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        timeProvider = MockTimeProvider(.currentTime)

        subject = AppProcessor(
            appModule: appModule,
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter
            )
        )
        subject.coordinator = coordinator.asAnyCoordinator()
    }

    override func tearDown() {
        super.tearDown()

        appModule = nil
        coordinator = nil
        subject = nil
        timeProvider = nil
    }
}
