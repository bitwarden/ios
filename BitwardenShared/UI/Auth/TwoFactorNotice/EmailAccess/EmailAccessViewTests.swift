import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - EmailAccessViewTests

class EmailAccessViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<EmailAccessState, EmailAccessAction, EmailAccessEffect>!
    var subject: EmailAccessView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(
            state: EmailAccessState(
                allowDelay: true,
                emailAddress: "person@example.com"
            )
        )
        let store = Store(processor: processor)

        subject = EmailAccessView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the continue button sends the `.continueTapped` effect
    @MainActor
    func test_continueButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.continue)
        try await button.tap()

        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .continueTapped)
    }

    // MARK: Previews

    /// The email access view renders correctly
    @MainActor
    func test_snapshot_emailAccessView() {
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape]
        )
    }

    @MainActor
    func test_snapshot_emailAccessView_longEmailAddress() {
        processor.state.emailAddress = "veryveryveryverylongname@veryveryveryverylongdomain.com"
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait]
        )
    }
}
