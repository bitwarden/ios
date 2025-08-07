import AuthenticationServices
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ExportCXFProcessorTests

class ExportCXFProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<ExportCXFRoute, Void>!
    var delegate: MockExportCXFProcessorDelegate!
    var errorReporter: MockErrorReporter!
    var exportCXFCiphersRepository: MockExportCXFCiphersRepository!
    var policyService: MockPolicyService!
    var stackNavigator: MockStackNavigator!
    var stateService: MockStateService!
    var subject: ExportCXFProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator<ExportCXFRoute, Void>()
        delegate = MockExportCXFProcessorDelegate()
        errorReporter = MockErrorReporter()
        exportCXFCiphersRepository = MockExportCXFCiphersRepository()
        policyService = MockPolicyService()
        stackNavigator = MockStackNavigator()
        stateService = MockStateService()
        vaultRepository = MockVaultRepository()
        subject = ExportCXFProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                exportCXFCiphersRepository: exportCXFCiphersRepository,
                policyService: policyService,
                stateService: stateService,
                vaultRepository: vaultRepository
            ),
            state: ExportCXFState()
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        coordinator = nil
        delegate = nil
        errorReporter = nil
        exportCXFCiphersRepository = nil
        policyService = nil
        stackNavigator = nil
        stateService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `perform(_:)` appeared loads the initial data.
    @MainActor
    func test_perform_appeared() async throws {
        try await preparesExportFromStatusTest(status: .start, fromAppeared: true)
    }

    /// `perform(_:)` appeared doesn't load the initial data when `.disablePersonalVaultExport`
    /// applies to user changing the status to failure.
    @MainActor
    func test_perform_appearedDisablePersonalVaultExportPolicy() async throws {
        policyService.policyAppliesToUserResult[.disablePersonalVaultExport] = true

        await subject.perform(.appeared)

        guard case let .failure(message) = subject.state.status else {
            XCTFail("Status should be failure")
            return
        }
        XCTAssertEqual(message, Localizations.disablePersonalVaultExportPolicyInEffect)
        XCTAssertTrue(subject.state.isFeatureUnavailable)
    }

    /// `perform(_:)` appeared logs when throwing getting all ciphers changing the status to failure.
    @MainActor
    func test_perform_appearedFailsLoadingData() async throws {
        try await preparesExportFromStatusFailsTest(status: .start, fromAppeared: true)
    }

    /// `perform(_:)` appeared loads the initial data but there are zero items
    /// so a failure state is displayed.
    @MainActor
    func test_perform_appearedZeroItems() async throws {
        try await preparesExportZeroItemsFromStatusTest(status: .start, fromAppeared: true)
    }

    /// `perform(_:)` with `.cancel` with shows confirmation and navigates to dismiss.
    @MainActor
    func test_perform_cancel() async throws {
        let task = Task {
            await subject.perform(.cancel)
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !coordinator.alertShown.isEmpty
        }

        let confirmCancelAlert = try XCTUnwrap(coordinator.alertShown.first)
        try await confirmCancelAlert.tapAction(title: Localizations.yes)

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !coordinator.routes.isEmpty
        }

        XCTAssertEqual(.dismiss, coordinator.routes.last)
    }

    /// `perform(_:)` with `.cancel` shows confirmation and
    /// doesn't navigate to dismiss if the user cancels the confirmation dialog.
    @MainActor
    func test_perform_cancelNoConfirmation() async throws {
        let task = Task {
            await subject.perform(.cancel)
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !coordinator.alertShown.isEmpty
        }

        let confirmCancelAlert = try XCTUnwrap(coordinator.alertShown.first)
        try await confirmCancelAlert.tapAction(title: Localizations.no)

        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `perform(_:)` with `.cancel` when feature unavailable navigates to dismiss.
    @MainActor
    func test_perform_cancelMainButtonNotShown() async throws {
        subject.state.isFeatureUnavailable = true

        await subject.perform(.cancel)

        XCTAssertEqual(.dismiss, coordinator.routes.last)
    }

    /// `perform(_:)` with `.mainButtonTapped` in `.start` status prepares export.
    @MainActor
    func test_perform_mainButtonTappedStartPreparesExport() async throws {
        try await preparesExportFromStatusTest(status: .start)
    }

    /// `perform(_:)` with `.mainButtonTapped` in `.start` status logs when throwing
    /// getting all ciphers changing the status to failure.
    @MainActor
    func test_perform_mainButtonTappedStartFails() async throws {
        try await preparesExportFromStatusFailsTest(status: .start)
    }

    /// `perform(_:)` with `.mainButtonTapped` in `.start` status tries to prepare the data
    /// but there are zero items so a failure state is displayed.
    @MainActor
    func test_perform_mainButtonTappedStartZeroItems() async throws {
        try await preparesExportZeroItemsFromStatusTest(status: .start, fromAppeared: true)
    }

    /// `perform(_:)` with `.mainButtonTapped` in `.failure` status prepares export.
    @MainActor
    func test_perform_mainButtonTappedFailurePreparesExport() async throws {
        try await preparesExportFromStatusTest(status: .failure(message: "failure"))
    }

    /// `perform(_:)` with `.mainButtonTapped` in `.failure` status logs when throwing
    /// getting all ciphers changing the status to failure.
    @MainActor
    func test_perform_mainButtonTappedFailureFails() async throws {
        try await preparesExportFromStatusFailsTest(status: .failure(message: "failure"))
    }

    /// `perform(_:)` with `.mainButtonTapped` in `.failure` status tries to prepare the data
    /// but there are zero items so a failure state is displayed.
    @MainActor
    func test_perform_mainButtonTappedFailureZeroItems() async throws {
        try await preparesExportZeroItemsFromStatusTest(status: .failure(message: "failure"), fromAppeared: true)
    }

    #if SUPPORTS_CXP

    /// `perform(_:)` with `.mainButtonTapped` in `.prepared` status starts export.
    @MainActor
    func test_perform_mainButtonTappedPreparedStartsExport() async throws {
        subject.state.status = .prepared(itemsToExport: [
            CXFCredentialsResult(count: 10, type: .password),
        ])

        if #available(iOS 26.0, *) {
            exportCXFCiphersRepository.getExportVaultDataForCXFResult =
                .success(
                    ASImportableAccount.fixture()
                )
        }

        await subject.perform(.mainButtonTapped)

        // this should never happen in the actual app but here is a test for it as well.
        guard #available(iOS 26.0, *) else {
            XCTAssertEqual(coordinator.alertShown.count, 1)
            XCTAssertEqual(coordinator.alertShown[0].title, Localizations.exportingFailed)
            return
        }

        XCTAssertNotNil(exportCXFCiphersRepository.exportCredentialsData)
        XCTAssertEqual(coordinator.loadingOverlaysShown[0].title, Localizations.loading)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `perform(_:)` with `.mainButtonTapped` in `.prepared` status does nothing when there's no delegate.
    @MainActor
    func test_perform_mainButtonTappedPreparedDoesNothingWhenDelegateNil() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("This test requires iOS 26.0")
        }

        subject = ExportCXFProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: nil,
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                exportCXFCiphersRepository: exportCXFCiphersRepository,
                stateService: stateService,
                vaultRepository: vaultRepository
            ),
            state: ExportCXFState()
        )
        subject.state.status = .prepared(itemsToExport: [
            CXFCredentialsResult(count: 10, type: .password),
        ])

        await subject.perform(.mainButtonTapped)

        XCTAssertNil(exportCXFCiphersRepository.exportCredentialsData)
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `perform(_:)` with `.mainButtonTapped` in `.prepared` status throws when getting export data.
    @MainActor
    func test_perform_mainButtonTappedPreparedThrowsGettingExportData() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("This test requires iOS 26.0")
        }

        subject.state.status = .prepared(itemsToExport: [
            CXFCredentialsResult(count: 10, type: .password),
        ])

        exportCXFCiphersRepository.getExportVaultDataForCXFResult = .failure(BitwardenTestError.example)

        await subject.perform(.mainButtonTapped)

        guard case let .failure(message) = subject.state.status else {
            XCTFail("Unexpected state: \(subject.state)")
            return
        }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(message, Localizations.thereHasBeenAnIssueExportingItems)
    }

    /// `perform(_:)` with `.mainButtonTapped` in `.prepared` status throws when exporting credentials.
    @MainActor
    func test_perform_mainButtonTappedPreparedThrowsExportingCredentials() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("This test requires iOS 26.0")
        }

        subject.state.status = .prepared(itemsToExport: [
            CXFCredentialsResult(count: 10, type: .password),
        ])

        exportCXFCiphersRepository.getExportVaultDataForCXFResult = .success(
            ASImportableAccount.fixture()
        )
        exportCXFCiphersRepository.exportCredentialsError = BitwardenTestError.example
        await subject.perform(.mainButtonTapped)

        guard case let .failure(message) = subject.state.status else {
            XCTFail("Unexpected state: \(subject.state)")
            return
        }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(message, Localizations.thereHasBeenAnIssueExportingItems)
    }

    /// `perform(_:)` with `.mainButtonTapped` in `.prepared` status throws `ASAuthorizationError.failed`
    /// when exporting credentials.
    @MainActor
    func test_perform_mainButtonTappedPreparedThrowsAuthorizationExportingCredentials() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("This test requires iOS 26.0")
        }

        subject.state.status = .prepared(itemsToExport: [
            CXFCredentialsResult(count: 10, type: .password),
        ])

        exportCXFCiphersRepository.getExportVaultDataForCXFResult = .success(
            ASImportableAccount.fixture()
        )
        exportCXFCiphersRepository.exportCredentialsError = ASAuthorizationError(.failed)
        await subject.perform(.mainButtonTapped)

        XCTAssertEqual(coordinator.alertShown[0].title, Localizations.exportingFailed)
        XCTAssertEqual(
            coordinator.alertShown[0].message,
            Localizations.youMayNeedToEnableDevicePasscodeOrBiometrics
        )
    }

    #else

    /// `perform(_:)` with `.mainButtonTapped` in `.prepared` status does nothing.
    @MainActor
    func test_perform_mainButtonTappedPreparedNothing() async throws {
        subject.state.status = .prepared(itemsToExport: [])
        await subject.perform(.mainButtonTapped)
        throw XCTSkip("This feature is available on iOS 26.0 or later compiling with Xcode 26.0 or later")
    }

    #endif

    // MARK: Private

    /// Prepares export in the given status.
    @MainActor
    func preparesExportFromStatusTest(
        status: ExportCXFState.ExportCXFStatus,
        fromAppeared: Bool = false
    ) async throws {
        subject.state.status = status
        exportCXFCiphersRepository.getAllCiphersToExportCXFResult = .success([.fixture()])
        exportCXFCiphersRepository.buildCiphersToExportSummaryResult = [
            CXFCredentialsResult(count: 10, type: .passkey),
            CXFCredentialsResult(count: 20, type: .card),
        ]

        if fromAppeared {
            await subject.perform(.appeared)
        } else {
            await subject.perform(.mainButtonTapped)
        }

        guard case let .prepared(itemsToExport) = subject.state.status else {
            XCTFail("Unexpected state: \(subject.state)")
            return
        }
        XCTAssertEqual(itemsToExport[0].type, .passkey)
        XCTAssertEqual(itemsToExport[0].count, 10)
        XCTAssertEqual(itemsToExport[1].type, .card)
        XCTAssertEqual(itemsToExport[1].count, 20)
    }

    /// Tests that prepares export in the given status logs when throwing
    /// getting all ciphers changing the status to failure.
    @MainActor
    func preparesExportFromStatusFailsTest(
        status: ExportCXFState.ExportCXFStatus,
        fromAppeared: Bool = false
    ) async throws {
        subject.state.status = status
        exportCXFCiphersRepository.getAllCiphersToExportCXFResult = .failure(BitwardenTestError.example)

        if fromAppeared {
            await subject.perform(.appeared)
        } else {
            await subject.perform(.mainButtonTapped)
        }

        guard case let .failure(message) = subject.state.status else {
            XCTFail("Unexpected state: \(subject.state)")
            return
        }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(message, Localizations.exportVaultFailure)
    }

    /// Tests that prepares export in the given status fails because of zero items in vault.
    @MainActor
    func preparesExportZeroItemsFromStatusTest(
        status: ExportCXFState.ExportCXFStatus,
        fromAppeared: Bool = false
    ) async throws {
        subject.state.status = status
        exportCXFCiphersRepository.getAllCiphersToExportCXFResult = .success([])

        if fromAppeared {
            await subject.perform(.appeared)
        } else {
            await subject.perform(.mainButtonTapped)
        }
        XCTAssertEqual(subject.state.status, .failure(message: Localizations.noItems))
        XCTAssertTrue(subject.state.isFeatureUnavailable)
    }
}

// MARK: - MockExportCXFProcessorDelegate

class MockExportCXFProcessorDelegate: ExportCXFProcessorDelegate {
    func presentationAnchorForASCredentialExportManager() -> ASPresentationAnchor {
        UIWindow()
    }
} // swiftlint:disable:this file_length
