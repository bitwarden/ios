import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

class PasswordHistoryListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<PasswordHistoryRoute, Void>!
    var errorReporter: MockErrorReporter!
    var generatorRepository: MockGeneratorRepository!
    var pasteboardService: MockPasteboardService!
    var subject: PasswordHistoryListProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        generatorRepository = MockGeneratorRepository()
        pasteboardService = MockPasteboardService()

        subject = PasswordHistoryListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                generatorRepository: generatorRepository,
                pasteboardService: pasteboardService
            ),
            state: PasswordHistoryListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        generatorRepository = nil
        pasteboardService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` starts streaming the password history.
    @MainActor
    func test_perform_appeared() {
        let passwordHistory = [
            PasswordHistoryView.fixture(password: "8gr6uY8CLYQwzr#"),
            PasswordHistoryView.fixture(password: "%w4&D*48&CD&j2"),
            PasswordHistoryView.fixture(password: "df@58^%8o7e@&@"),
        ]
        generatorRepository.passwordHistorySubject.value = passwordHistory

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor { !subject.state.passwordHistory.isEmpty }
        task.cancel()

        XCTAssertEqual(subject.state.passwordHistory, passwordHistory)
    }

    /// `perform(_:)` with `.appeared` records an error if applicable.
    func test_perform_appeared_error() {
        generatorRepository.passwordHistorySubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor { !errorReporter.errors.isEmpty }
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.appeared` doesn't load anything if the password history is already set.
    @MainActor
    func test_perform_appeared_sourceItem() async {
        let passwordHistory = [
            PasswordHistoryView.fixture(password: "8gr6uY8CLYQwzr#"),
            PasswordHistoryView.fixture(password: "%w4&D*48&CD&j2"),
            PasswordHistoryView.fixture(password: "df@58^%8o7e@&@"),
        ]
        subject.state.source = .item(passwordHistory)

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.passwordHistory, passwordHistory)
    }

    /// `perform(_:)` with `.clearList` tells the repository to clear the password history.
    func test_perform_clearList() async {
        await subject.perform(.clearList)
        XCTAssertTrue(generatorRepository.clearPasswordHistoryCalled)
    }

    /// `perform(_:)` with `.clearList` records an error if applicable.
    func test_perform_clearList_error() async {
        generatorRepository.clearPasswordHistoryResult = .failure(BitwardenTestError.example)

        await subject.perform(.clearList)

        XCTAssertTrue(generatorRepository.clearPasswordHistoryCalled)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `receive(_:)` with `.copyPassword` copies the generated password to the system pasteboard
    /// and shows a toast.
    @MainActor
    func test_receive_copyPassword() {
        subject.receive(.copyPassword(.fixture(password: "PASSWORD")))
        XCTAssertEqual(pasteboardService.copiedString, "PASSWORD")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.password)))
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.password))
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }
}
