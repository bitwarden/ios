import SwiftUI
import XCTest

@testable import BitwardenShared

class MasterPasswordGeneratorProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var generatorRepository: MockGeneratorRepository!
    var subject: MasterPasswordGeneratorProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        generatorRepository = MockGeneratorRepository()

        subject = MasterPasswordGeneratorProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                generatorRepository: generatorRepository
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        generatorRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.loadData` generates the initial password.
    @MainActor
    func test_perform_loadData() async {
        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.generatedPassword, "MASTER_PASSWORD")
    }

    /// `perform(_:)` with `.generate` generates another password.
    @MainActor
    func test_perform_generate() async {
        generatorRepository.masterPasswordGeneratorResult = .success("SECOND_PASSWORD")

        await subject.perform(.generate)

        XCTAssertEqual(subject.state.generatedPassword, "SECOND_PASSWORD")
    }

    /// `perform(_:)` with `.generate` logs an error and shows an alert if the request fails.
    @MainActor
    func test_perform_generate_error() async {
        generatorRepository.masterPasswordGeneratorResult = .failure(BitwardenTestError.example)

        await subject.perform(.generate)

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// `receive(_:)` with `.preventAccountLock` shows the prevent account lock screen.
    @MainActor
    func test_receive_save() {
        subject.receive(.preventAccountLock)
        XCTAssertEqual(coordinator.routes.last, .preventAccountLock)
    }

    /// `receive(_:)` with `.save` dismisses the view.
    @MainActor
    func test_receive_save() async {
        await subject.perform(.save)
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// `receive(_:)` with `.masterPasswordChanged(String)` changes the master password.
    @MainActor
    func test_receive_masterPasswordChanged() {
        let updatedPassword = "XxLimpBizkit4Eva!xX"
        subject.receive(.masterPasswordChanged(updatedPassword))
        XCTAssertEqual(subject.state.generatedPassword, updatedPassword)
    }
}
