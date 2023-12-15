import BitwardenSdk
import XCTest

@testable import BitwardenShared

class FoldersProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var coordinator: MockCoordinator<SettingsRoute>!
    var settingsRepository: MockSettingsRepository!
    var subject: FoldersProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        coordinator = MockCoordinator<SettingsRoute>()
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

    /// `perform(_:)` with `.streamFolders` updates the state's list of folders whenever it changes.
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
    func test_receive_add() {
        subject.receive(.add)

        XCTAssertEqual(coordinator.routes.last, .addEditFolder(folder: nil))
    }

    /// Receiving `.folderTapped(id:)` navigates to the edit folder screen.
    func test_receive_folderTapped() {
        let folder = FolderView.fixture()
        subject.state.folders = [folder]

        subject.receive(.folderTapped(id: folder.id))

        XCTAssertEqual(coordinator.routes.last, .addEditFolder(folder: folder))
    }
}
