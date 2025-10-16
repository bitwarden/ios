import XCTest

@testable import BitwardenShared

class ReviewPromptDataTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(reviewPromptShownForVersion:userActions:)` initializes the data with the provided values.
    func test_init_reviewPromptData() {
        let subject = ReviewPromptData(
            reviewPromptShownForVersion: "1.2",
            userActions: [
                UserActionItem(
                    userAction: .addedNewItem,
                    count: 3,
                ),
            ],
        )

        XCTAssertEqual(subject.reviewPromptShownForVersion, "1.2")
        XCTAssertEqual(subject.userActions, [
            UserActionItem(
                userAction: .addedNewItem,
                count: 3,
            ),
        ])
    }

    /// `init()` initializes the `ReviewPromptData` with the default values.
    func test_init_defaultValues() {
        let subject = ReviewPromptData()

        XCTAssertTrue(subject.userActions.isEmpty)
        XCTAssertNil(subject.reviewPromptShownForVersion)
    }

    /// `addUserAction(_:)` increments the count of the user action if it already exists.
    func test_addUserAction_incrementCount() {
        var subject = ReviewPromptData(
            reviewPromptShownForVersion: "1.2",
            userActions: [
                UserActionItem(
                    userAction: .addedNewItem,
                    count: 3,
                ),
                UserActionItem(
                    userAction: .createdNewSend,
                    count: 1,
                ),
            ],
        )

        subject.addUserAction(.createdNewSend)

        XCTAssertEqual(subject.userActions, [
            UserActionItem(
                userAction: .addedNewItem,
                count: 3,
            ),
            UserActionItem(
                userAction: .createdNewSend,
                count: 2,
            ),
        ])
    }

    /// `addUserAction(_:)` creates a new user action if it does not already exist.
    func test_addUserAction_createNewAction() {
        var subject = ReviewPromptData(reviewPromptShownForVersion: "1.2")

        subject.addUserAction(.createdNewSend)

        XCTAssertEqual(subject.userActions, [
            UserActionItem(
                userAction: .createdNewSend,
                count: 1,
            ),
        ])
    }
}
