import XCTest

@testable import BitwardenShared

// MARK: - ImportCXPCoordinatorTests

class ImportCXPCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var importCiphersRepository: MockImportCiphersRepository!
    var stackNavigator: MockStackNavigator!
    var stateService: MockStateService!
    var subject: ImportCXPCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        importCiphersRepository = MockImportCiphersRepository()
        stackNavigator = MockStackNavigator()
        stateService = MockStateService()

        subject = ImportCXPCoordinator(
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                importCiphersRepository: importCiphersRepository,
                stateService: stateService
            ),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        errorReporter = nil
        importCiphersRepository = nil
        stackNavigator = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:context:)` with `.dismiss`, calls dismiss in the stack navigator.
    @MainActor
    func test_navigate_dismiss() {
        subject.navigate(to: .dismiss)
        XCTAssertTrue(stackNavigator.actions.contains(where: { action in
            action.type == .dismissed
        }))
    }

    /// `navigate(to:context:)` with `.importCredentials`, shows the import processor.
    @MainActor
    func test_navigate_importCredentials() throws {
        subject
            .navigate(
                to: .importCredentials(
                    credentialImportToken: UUID(
                        uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec"
                    )!
                )
            )

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is ImportCXPView)
    }

    /// `start()` has no effect.
    @MainActor
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}
