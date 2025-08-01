import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

class AddEditFolderProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AddEditFolderRoute, Void>!
    var delegate: MockAddEditFolderDelegate!
    var errorReporter: MockErrorReporter!
    var settingsRepository: MockSettingsRepository!
    var subject: AddEditFolderProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<AddEditFolderRoute, Void>()
        delegate = MockAddEditFolderDelegate()
        errorReporter = MockErrorReporter()
        settingsRepository = MockSettingsRepository()
        let settings = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            settingsRepository: settingsRepository
        )
        subject = AddEditFolderProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: settings,
            state: AddEditFolderState(mode: .add)
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        delegate = nil
        errorReporter = nil
        settingsRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.deleteTapped` presents the confirmation alert and displays an error if
    /// deleting the folder failed.
    @MainActor
    func test_perform_deleteTapped_genericError() async throws {
        // Set up the mock data.
        subject.state.mode = .edit(.fixture(id: "testID"))
        settingsRepository.deleteFolderResult = .failure(BitwardenTestError.example)

        await subject.perform(.deleteTapped)

        // Ensure the alert is shown.
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .confirmDeleteFolder {})

        // Press the "Yes" button on the alert.
        try await alert.tapAction(title: Localizations.yes)

        // Ensure the error alert is displayed.
        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.deleteTapped` presents the confirmation alert and displays a network error with a try again
    /// button if deleting the folder failed for a networking reason.
    @MainActor
    func test_perform_deleteTapped_networkError() async throws {
        // Set up the mock data.
        subject.state.mode = .edit(.fixture(id: "testID"))
        let error = URLError(.timedOut)
        settingsRepository.deleteFolderResult = .failure(error)

        await subject.perform(.deleteTapped)

        // Ensure the alert is shown.
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .confirmDeleteFolder {})

        // Press the "Yes" button on the alert.
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(settingsRepository.deletedFolderId, "testID")

        // Ensure the error alert is displayed.
        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? URLError, error)
        XCTAssertEqual(errorReporter.errors.first as? URLError, URLError(.timedOut))

        // The try again button should retry the call.
        settingsRepository.deletedFolderId = nil
        let tryAgainAction = try XCTUnwrap(alert.alertActions.first)
        await tryAgainAction.handler?(tryAgainAction, [])
        XCTAssertEqual(settingsRepository.deletedFolderId, "testID")
    }

    /// `perform(_:)` with `.deleteTapped` presents the confirmation alert and deletes the account if the user confirms.
    @MainActor
    func test_perform_deleteTapped_success() async throws {
        // Set up the mock data.
        subject.state.mode = .edit(.fixture(id: "testID"))

        await subject.perform(.deleteTapped)

        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .confirmDeleteFolder {})

        // Press the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        // Ensure the folder is deleted and the view is dismissed.
        XCTAssertEqual(settingsRepository.deletedFolderId, "testID")
        XCTAssertEqual(coordinator.routes.last, .dismiss)
        XCTAssertTrue(delegate.folderDeletedCalled)
    }

    /// `perform(_:)` with `.savePressed` displays an alert if name field is invalid.
    @MainActor
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

    /// `perform(_:)` with `.savePressed` displays an alert if adding a new folder fails.
    @MainActor
    func test_perform_savePressed_genericErrorAlert_add() async throws {
        subject.state.folderName = "Folder Name"
        settingsRepository.addFolderResult = .failure(BitwardenTestError.example)

        await subject.perform(.saveTapped)

        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.savePressed` displays an alert if editing an existing folder fails.
    @MainActor
    func test_perform_savePressed_genericErrorAlert_edit() async throws {
        let folderName = "FolderName"
        subject.state.mode = .edit(.fixture(name: folderName))
        subject.state.folderName = folderName
        settingsRepository.editFolderResult = .failure(BitwardenTestError.example)

        await subject.perform(.saveTapped)

        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.savePressed` displays a network error alert with a try again button if there was a
    /// networking error.
    @MainActor
    func test_perform_savePressed_networkError() async throws {
        subject.state.folderName = "Folder Name"
        let error = URLError(.timedOut)
        settingsRepository.addFolderResult = .failure(error)

        await subject.perform(.saveTapped)

        XCTAssertEqual(settingsRepository.addedFolderName, "Folder Name")

        let errorAlertsWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertsWithRetry.error as? URLError, error)
        XCTAssertEqual(errorReporter.errors.first as? URLError, error)

        // The try again button should retry the call.
        settingsRepository.addedFolderName = nil
        await errorAlertsWithRetry.retry()
        XCTAssertEqual(settingsRepository.addedFolderName, "Folder Name")
    }

    /// `perform(_:)` with `.savePressed` adds the new folder.
    @MainActor
    func test_perform_savePressed_add() async {
        let folderName = "FolderName"
        let folderAdded = FolderView.fixture(name: folderName)
        settingsRepository.addFolderResult = .success(folderAdded)

        subject.state.folderName = folderName
        await subject.perform(.saveTapped)

        XCTAssertEqual(settingsRepository.addedFolderName, folderName)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
        XCTAssertTrue(delegate.folderAddedCalled)
        XCTAssertEqual(delegate.folderAddedFolder, folderAdded)
    }

    /// `perform(_:)` with `.savePressed` edits the existing folder.
    @MainActor
    func test_perform_savePressed_edit() async {
        let folderName = "FolderName"
        subject.state.mode = .edit(.fixture(name: folderName))
        subject.state.folderName = folderName
        await subject.perform(.saveTapped)

        XCTAssertEqual(settingsRepository.editedFolderName, folderName)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
        XCTAssertTrue(delegate.folderEditedCalled)
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.folderNameTextChanged(_:)` updates the state to reflect the change.
    @MainActor
    func test_receive_folderNameTextChanged() {
        subject.state.folderName = ""
        XCTAssertTrue(subject.state.folderName.isEmpty)

        subject.receive(.folderNameTextChanged("updated name"))
        XCTAssertTrue(subject.state.folderName == "updated name")
    }
}

class MockAddEditFolderDelegate: AddEditFolderDelegate {
    var folderAddedCalled = false
    var folderAddedFolder: FolderView?
    var folderDeletedCalled = false
    var folderEditedCalled = false

    func folderAdded(_ folderView: FolderView) {
        folderAddedCalled = true
        folderAddedFolder = folderView
    }

    func folderDeleted() {
        folderDeletedCalled = true
    }

    func folderEdited() {
        folderEditedCalled = true
    }
}
