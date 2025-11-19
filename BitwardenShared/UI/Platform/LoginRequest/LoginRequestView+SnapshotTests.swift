// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - ViewItemViewTests

class LoginRequestViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<LoginRequestState, LoginRequestAction, LoginRequestEffect>!
    var subject: LoginRequestView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: LoginRequestState(request: .fixture(
            fingerprintPhrase: "i-asked-chat-gpt-but-it-said-no",
        )))
        let store = Store(processor: processor)

        subject = LoginRequestView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The default view renders correctly.
    func disabletest_snapshot() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 2),
            ],
        )
    }
}
