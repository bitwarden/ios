import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - ExportCXFCoordinatorTests

class ExportCXFCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var exportCXFCiphersRepository: MockExportCXFCiphersRepository!
    var stackNavigator: MockStackNavigator!
    var stateService: MockStateService!
    var subject: ExportCXFCoordinator!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        exportCXFCiphersRepository = MockExportCXFCiphersRepository()
        stackNavigator = MockStackNavigator()
        stateService = MockStateService()
        vaultRepository = MockVaultRepository()
        subject = ExportCXFCoordinator(
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                exportCXFCiphersRepository: exportCXFCiphersRepository,
                stateService: stateService,
                vaultRepository: vaultRepository,
            ),
            stackNavigator: stackNavigator,
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        errorReporter = nil
        exportCXFCiphersRepository = nil
        stackNavigator = nil
        stateService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `start()` shows the Credential Exchange export view.
    @MainActor
    func test_start_showsExportCXF() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.last?.view is ExportCXFView)
    }
}
