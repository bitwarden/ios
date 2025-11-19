import XCTest

@testable import BitwardenShared

class ReviewPromptServiceTests: BitwardenTestCase {
    // MARK: Properties

    var identityStore: MockCredentialIdentityStore!
    var stateService: MockStateService!
    var subject: ReviewPromptService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        identityStore = MockCredentialIdentityStore()
        stateService = MockStateService()

        subject = DefaultReviewPromptService(
            appVersion: "1.0",
            identityStore: identityStore,
            stateService: stateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        identityStore = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `clearUserActions()` clears the list of tracked user actions.
    func test_clearUserActions() async {
        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(userAction: .addedNewItem, count: 3),
            ],
        )

        await subject.clearUserActions()

        XCTAssertTrue(stateService.reviewPromptData?.userActions.isEmpty ?? false)
    }

    /// `isEligibleForReviewPrompt()` returns false if auto-fill is disabled.
    func test_isEligibleForReviewPrompt_autoFillDisabled() async throws {
        identityStore.state.mockIsEnabled = false
        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(
                    userAction: .addedNewItem,
                    count: 3,
                ),
            ],
        )
        let isEligible = await subject.isEligibleForReviewPrompt()

        XCTAssertFalse(isEligible)
    }

    /// `isEligibleForReviewPrompt()` returns false if the review prompt has been shown for this version.
    func test_isEligibleForReviewPrompt_reviewPromptShownForVersionMatch() async throws {
        identityStore.state.mockIsEnabled = true
        stateService.reviewPromptData = ReviewPromptData(
            reviewPromptShownForVersion: "1.0",
            userActions: [
                UserActionItem(
                    userAction: .addedNewItem,
                    count: 3,
                ),
            ],
        )
        let isEligible = await subject.isEligibleForReviewPrompt()

        XCTAssertFalse(isEligible)
    }

    /// `isEligibleForReviewPrompt()` returns correct value based on user actions.
    func test_isEligibleForReviewPrompt_userActions() async throws {
        identityStore.state.mockIsEnabled = true
        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(userAction: .addedNewItem, count: 3),
            ],
        )
        let isEligibleViaNewItem = await subject.isEligibleForReviewPrompt()
        XCTAssertTrue(
            isEligibleViaNewItem,
            "User should be eligible for review prompt after adding 3 new items.",
        )

        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(userAction: .createdNewSend, count: 3),
            ],
        )
        let isEligibleViaNewSend = await subject.isEligibleForReviewPrompt()
        XCTAssertTrue(
            isEligibleViaNewSend,
            "User should be eligible for review prompt after creating 3 new sends.",
        )

        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(userAction: .copiedOrInsertedGeneratedValue, count: 3),
            ],
        )

        let isEligibleViaCopy = await subject.isEligibleForReviewPrompt()
        XCTAssertTrue(
            isEligibleViaCopy,
            "User should be eligible for review prompt after 3 copying or inserting generated values.",
        )

        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(userAction: .copiedOrInsertedGeneratedValue, count: 2),
                UserActionItem(userAction: .addedNewItem, count: 1),
                UserActionItem(userAction: .createdNewSend, count: 2),
            ],
        )
        let isEligible = await subject.isEligibleForReviewPrompt()
        XCTAssertFalse(
            isEligible,
            "User shouldn't be eligible if none of the user actions was repeated 3 times.",
        )
    }

    /// `trackUserAction(_:)` adds the user action to the list of tracked actions.
    func test_trackUserAction() async {
        let action: UserAction = .addedNewItem
        await subject.trackUserAction(action)

        let userActions = stateService.reviewPromptData?.userActions
        XCTAssertEqual(userActions?.count, 1)
        XCTAssertEqual(userActions?.first?.userAction, action)
        XCTAssertEqual(userActions?.first?.count, 1)
    }

    /// `trackUserAction(_:)` increments the count of the user action if it already exists.
    func test_trackUserAction_incrementCount() async {
        let action: UserAction = .addedNewItem
        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(userAction: action, count: 3),
            ],
        )

        await subject.trackUserAction(action)

        let userActions = stateService.reviewPromptData?.userActions
        XCTAssertEqual(userActions?.count, 1)
        XCTAssertEqual(userActions?.first?.userAction, action)
        XCTAssertEqual(userActions?.first?.count, 4)
    }

    /// `trackUserAction(_:)` doesn't increment the count of the user action if the review prompt has
    /// already been shown for the current version.
    func test_trackUserAction_reviewPromptShownForVersionMatch() async {
        let action: UserAction = .addedNewItem
        stateService.reviewPromptData = ReviewPromptData(
            reviewPromptShownForVersion: "1.0",
            userActions: [
                UserActionItem(userAction: action, count: 3),
            ],
        )

        await subject.trackUserAction(action)

        let userActions = stateService.reviewPromptData?.userActions
        XCTAssertEqual(userActions?.count, 1)
        XCTAssertEqual(userActions?.first?.userAction, action)
        XCTAssertEqual(userActions?.first?.count, 3)
    }

    /// `setReviewPromptShownVersion()` sets the review prompt shown version to the current app version.
    func test_setReviewPromptShownVersion() async {
        XCTAssertNil(stateService.reviewPromptData?.reviewPromptShownForVersion)
        await subject.setReviewPromptShownVersion()

        XCTAssertEqual(stateService.reviewPromptData?.reviewPromptShownForVersion, "1.0")
    }
}
