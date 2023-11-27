import BitwardenSdk
import XCTest

@testable import BitwardenShared

class GeneratorHistoryProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<GeneratorRoute>!
    var generatorRepository: MockGeneratorRepository!
    var pasteboardService: MockPasteboardService!
    var subject: GeneratorHistoryProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        generatorRepository = MockGeneratorRepository()
        pasteboardService = MockPasteboardService()

        subject = GeneratorHistoryProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                generatorRepository: generatorRepository,
                pasteboardService: pasteboardService
            ),
            state: GeneratorHistoryState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        generatorRepository = nil
        pasteboardService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` starts streaming the password history.
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

    /// `perform(_:)` with `.clearList` tells the repository to clear the password history.
    func test_perform_clearList() async {
        await subject.perform(.clearList)
        XCTAssertTrue(generatorRepository.clearPasswordHistoryCalled)
    }

    /// `receive(_:)` with `.copyPassword` copies the generated password to the system pasteboard
    /// and shows a toast.
    func test_receive_copyPassword() {
        subject.receive(.copyPassword(.fixture(password: "PASSWORD")))
        XCTAssertEqual(pasteboardService.copiedString, "PASSWORD")
        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.password))
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.password))
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }
}
