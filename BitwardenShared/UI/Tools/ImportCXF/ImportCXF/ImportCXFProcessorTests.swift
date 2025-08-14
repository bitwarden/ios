import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ImportCXFProcessorTests

class ImportCXFProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<ImportCXFRoute, Void>!
    var errorReporter: MockErrorReporter!
    var importCiphersRepository: MockImportCiphersRepository!
    var policyService: MockPolicyService!
    var state: ImportCXFState!
    var stateService: MockStateService!
    var subject: ImportCXFProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator<ImportCXFRoute, Void>()
        errorReporter = MockErrorReporter()
        importCiphersRepository = MockImportCiphersRepository()
        policyService = MockPolicyService()
        state = ImportCXFState()
        stateService = MockStateService()
        subject = ImportCXFProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                importCiphersRepository: importCiphersRepository,
                policyService: policyService,
                stateService: stateService
            ),
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        coordinator = nil
        errorReporter = nil
        importCiphersRepository = nil
        policyService = nil
        state = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` sets the status as `.failure` with a message
    /// when the feature flag `.cxpImportMobile` is not enabled.
    @MainActor
    func test_perform_appearedNoFeatureFlag() async {
        await subject.perform(.appeared)
        guard case let .failure(message) = subject.state.status else {
            XCTFail("Status should be failure")
            return
        }
        XCTAssertEqual(message, Localizations.importingFromAnotherProviderIsNotAvailableForThisDevice)
    }

    /// `perform(_:)` with `.appeared` sets the status as `.failure` with a message
    /// when the feature flag `.cxpImportMobile` is enabled. but `.personalOwnership`
    /// policy applies to user.
    @MainActor
    func test_perform_appearedPersonalOwnership() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("CXP Import feature is not available on this device")
        }

        configService.featureFlagsBool[.cxpImportMobile] = true
        policyService.policyAppliesToUserResult[.personalOwnership] = true

        await subject.perform(.appeared)

        guard case let .failure(message) = subject.state.status else {
            XCTFail("Status should be failure")
            return
        }
        XCTAssertEqual(message, Localizations.personalOwnershipPolicyInEffect)
        XCTAssertTrue(subject.state.isFeatureUnavailable)
    }

    /// `perform(_:)` with `.appeared` doesn't set the status as `.failure`
    /// when the feature flag `.cxpImportMobile` is enabled and `.personalOwnership`
    /// policy doesn't apply to user.
    @MainActor
    func test_perform_appearedFeatureFlagEnabled() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("CXP Import feature is not available on this device")
        }

        configService.featureFlagsBool[.cxpImportMobile] = true
        await subject.perform(.appeared)
        if case .failure = subject.state.status {
            XCTFail("Status shouldn't be failure when CXP import is enabled")
        }
    }

    /// `perform(_:)` with `.cancel` with feature available shows confirmation and navigates to dismiss.
    @MainActor
    func test_perform_cancel() async throws {
        subject.state.isFeatureUnavailable = false
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

    /// `perform(_:)` with `.cancel` with feature available shows confirmation and
    /// doesn't navigate to dismiss if the user cancels the confirmation dialog.
    @MainActor
    func test_perform_cancelNoConfirmation() async throws {
        subject.state.isFeatureUnavailable = false
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

    /// `perform(_:)` with `.cancel` with feature unavailable navigates to dismiss.
    @MainActor
    func test_perform_cancelFeatureUnavailable() async throws {
        subject.state.isFeatureUnavailable = true
        let task = Task {
            await subject.perform(.cancel)
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !coordinator.routes.isEmpty
        }

        XCTAssertEqual(.dismiss, coordinator.routes.last)
    }

    /// `perform(_:)` with `.mainButtonTapped` with `.start` status.
    @MainActor
    func test_perform_mainButtonTappedStart() async throws {
        subject.state.status = .start
        subject.state.credentialImportToken = UUID(uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec")
        try await perform_mainButtonTapped_startImport()
    }

    /// `perform(_:)` with `.mainButtonTapped` with `.failure` status.
    @MainActor
    func test_perform_mainButtonTappedFailure() async throws {
        subject.state.status = .failure(message: "Error")
        subject.state.credentialImportToken = UUID(uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec")
        try await perform_mainButtonTapped_startImport()
    }

    /// `perform(_:)` with `.mainButtonTapped` with `.success` status which dismisses the view.
    @MainActor
    func test_perform_mainButtonTappedSuccess() async throws {
        subject.state.status = .success(totalImportedCredentials: 10, importedResults: [])
        subject.state.credentialImportToken = UUID(uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec")

        await subject.perform(.mainButtonTapped)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `perform(_:)` with `.mainButtonTapped` with `.start` status but no data found.
    @MainActor
    func test_perform_mainButtonTappedStartNoDataFound() async throws {
        guard try checkCompiler() else {
            return
        }

        subject.state.status = .start
        subject.state.credentialImportToken = UUID(uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec")

        importCiphersRepository.importCiphersResult.withVerification { _ in
            self.subject.state.status == .importing
        }.throwing(ImportCiphersRepositoryError.noDataFound)

        await subject.perform(.mainButtonTapped)

        guard checkAlertShownWhenNotInCorrectIOSVersion() else {
            return
        }

        guard case let .failure(message) = subject.state.status else {
            XCTFail("Importing status is not failure.")
            return
        }

        XCTAssertEqual(message, "No data found to import.")
    }

    /// `perform(_:)` with `.mainButtonTapped` with `.start` status but data encoding failed.
    @MainActor
    func test_perform_mainButtonTappedStartDataEncodingFailed() async throws {
        guard try checkCompiler() else {
            return
        }

        subject.state.status = .start
        subject.state.credentialImportToken = UUID(uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec")

        importCiphersRepository.importCiphersResult.withVerification { _ in
            self.subject.state.status == .importing
        }.throwing(ImportCiphersRepositoryError.dataEncodingFailed)

        await subject.perform(.mainButtonTapped)

        guard checkAlertShownWhenNotInCorrectIOSVersion() else {
            return
        }

        guard case let .failure(message) = subject.state.status else {
            XCTFail("Importing status is not failure.")
            return
        }

        XCTAssertEqual(message, "Import data encoding failed.")
    }

    /// `perform(_:)` with `.mainButtonTapped` with `.start` status but throws error.
    @MainActor
    func test_perform_mainButtonTappedStartThrowing() async throws {
        guard try checkCompiler() else {
            return
        }

        subject.state.status = .start
        subject.state.credentialImportToken = UUID(uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec")

        importCiphersRepository.importCiphersResult.withVerification { _ in
            self.subject.state.status == .importing
        }.throwing(BitwardenTestError.example)

        await subject.perform(.mainButtonTapped)

        guard checkAlertShownWhenNotInCorrectIOSVersion() else {
            return
        }

        guard case let .failure(message) = subject.state.status else {
            XCTFail("Importing status is not failure.")
            return
        }

        XCTAssertEqual(message, Localizations.thereWasAnIssueImportingAllOfYourPasswordsNoDataWasDeleted)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    // MARK: Private

    /// Performs `.perform(.mainButtonTapped)` to start import and checks everything went good.
    @MainActor
    private func perform_mainButtonTapped_startImport() async throws {
        guard try checkCompiler() else {
            return
        }

        let expectedResults = [
            CXFCredentialsResult(count: 12, type: .password),
            CXFCredentialsResult(count: 7, type: .passkey),
            CXFCredentialsResult(count: 11, type: .card),
        ]
        importCiphersRepository.importCiphersResult.withVerification { _ in
            self.subject.state.status == .importing
        }.withResult(expectedResults)

        await subject.perform(.mainButtonTapped)

        guard checkAlertShownWhenNotInCorrectIOSVersion() else {
            return
        }

        guard case let .success(total, results) = subject.state.status else {
            XCTFail("Importing status is not success.")
            return
        }

        XCTAssertEqual(total, 30)
        XCTAssertEqual(results, expectedResults)
    }

    /// Checks whether the appropriate compiler is being used to have the code available.
    /// - Returns: `true` if the compiler is correct, `false`otherwise.
    private func checkCompiler() throws -> Bool {
        #if SUPPORTS_CXP
        return true
        #else
        throw XCTSkip("CXP Import works only from 6.0.3 compiler.")
        #endif
    }

    /// Checks whether the alert is shown when not in the correct iOS version for CXF Import to work.
    @MainActor
    private func checkAlertShownWhenNotInCorrectIOSVersion() -> Bool {
        guard #available(iOS 26.0, *) else {
            XCTAssertEqual(
                coordinator.alertShown,
                [
                    .defaultAlert(
                        title: Localizations.importError,
                        message: Localizations.importingFromAnotherProviderIsNotAvailableForThisDevice
                    ),
                ]
            )
            return false
        }

        return true
    }
}
