import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class FoldersProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var settingsRepository: MockSettingsRepository!
    var subject: FoldersProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        settingsRepository = MockSettingsRepository()
        let services = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            settingsRepository: settingsRepository
        )
        subject = FoldersProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: FoldersState()
        )
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        coordinator = nil
        settingsRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `folderAdded()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_folderAdded() {
        XCTAssertNil(subject.state.toast)

        subject.folderAdded(.fixture())
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.folderCreated))
    }

    /// `folderDeleted()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_folderDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.folderDeleted()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.folderDeleted))
    }

    /// `folderEdited()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_folderEdited() {
        XCTAssertNil(subject.state.toast)

        subject.folderEdited()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.folderUpdated))
    }

    /// `perform(_:)` with `.streamFolders` updates the state's list of folders whenever it changes.
    @MainActor
    func test_perform_streamFolders() {
        let task = Task {
            await subject.perform(.streamFolders)
        }

        let folderView = FolderView.fixture()
        settingsRepository.foldersListSubject.value = [folderView]

        waitFor { subject.state.folders.isEmpty == false }
        task.cancel()

        XCTAssertEqual(subject.state.folders, [folderView])
    }

    /// `perform(_:)` with `.streamFolders` logs an error if getting the list of folders fails.
    func test_perform_streamLastSyncTime_error() async {
        settingsRepository.foldersListError = StateServiceError.noActiveAccount

        await subject.perform(.streamFolders)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// Receiving `.add` navigates to the add folder screen.
    @MainActor
    func test_receive_add() {
        subject.receive(.add)

        XCTAssertEqual(coordinator.routes.last, .addEditFolder(folder: nil))
    }

    /// Receiving `.folderTapped(id:)` navigates to the edit folder screen.
    @MainActor
    func test_receive_folderTapped() throws {
        let folder = FolderView.fixture()
        subject.state.folders = [folder]

        try subject.receive(.folderTapped(id: XCTUnwrap(folder.id)))

        XCTAssertEqual(coordinator.routes.last, .addEditFolder(folder: folder))
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(title: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }
}
