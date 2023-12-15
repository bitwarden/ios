import XCTest

@testable import BitwardenShared

class AddEditFolderProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var errorReporter: MockErrorReporter!
    var settingsRepository: MockSettingsRepository!
    var subject: AddEditFolderProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        errorReporter = MockErrorReporter()
        settingsRepository = MockSettingsRepository()
        let settings = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            settingsRepository: settingsRepository
        )
        subject = AddEditFolderProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: settings,
            state: AddEditFolderState(mode: .add)
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        settingsRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.savePressed` displays an alert if name field is invalid.
    func test_perform_savePressed_invalidName() async throws {
        subject.state.folderName = "    "

        await subject.perform(.saveTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.validationFieldRequired(Localizations.name),
                alertActions: [AlertAction(title: Localizations.ok, style: .default)]
            )
        )
    }

    /// `perform(_:)` with `.savePressed` displays an alert if saving or updating fails.
    func test_perform_savePressed_genericErrorAlert() async throws {
        subject.state.folderName = "Folder Name"
        struct TestError: Error, Equatable {}
        settingsRepository.addFolderResult = .failure(TestError())

        await subject.perform(.saveTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                alertActions: [AlertAction(title: Localizations.ok, style: .default)]
            )
        )
        XCTAssertEqual(errorReporter.errors.first as? TestError, TestError())
    }

    /// `perform(_:)` with `.savePressed` saves the item.
    func test_perform_savePressed() async {
        subject.state.folderName = "Folder Name"
        await subject.perform(.saveTapped)

        XCTAssertEqual(settingsRepository.addedFolderName, "Folder Name")
    }

    /// Receiving `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.folderNameTextChanged(_:)` updates the state to reflect the change.
    func test_receive_folderNameTextChanged() {
        subject.state.folderName = ""
        XCTAssertTrue(subject.state.folderName.isEmpty)

        subject.receive(.folderNameTextChanged("updated name"))
        XCTAssertTrue(subject.state.folderName == "updated name")
    }
}
