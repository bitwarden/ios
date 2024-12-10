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
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        identityStore = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `isEligibleForReviewPrompt()` returns false if auto-fill is disabled.
    func test_isEligibleForReviewPrompt_autoFillDisabled() async throws {
        identityStore.state.mockIsEnabled = false
        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(
                    userAction: .addedNewItem,
                    count: 3
                ),
            ]
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
                    count: 3
                ),
            ]
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
            ]
        )
        let isEligibleViaNewItem = await subject.isEligibleForReviewPrompt()
        XCTAssertTrue(
            isEligibleViaNewItem,
            "User should be eligible for review prompt after adding 3 new items."
        )

        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(userAction: .createdNewSend, count: 3),
            ]
        )
        let isEligibleViaNewSend = await subject.isEligibleForReviewPrompt()
        XCTAssertTrue(
            isEligibleViaNewSend,
            "User should be eligible for review prompt after creating 3 new sends."
        )

        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(userAction: .copiedOrInsertedGeneratedValue, count: 3),
            ]
        )

        let isEligibleViaCopy = await subject.isEligibleForReviewPrompt()
        XCTAssertTrue(
            isEligibleViaCopy,
            "User should be eligible for review prompt after 3 copying or inserting generated values."
        )

        stateService.reviewPromptData = ReviewPromptData(
            userActions: [
                UserActionItem(userAction: .copiedOrInsertedGeneratedValue, count: 2),
                UserActionItem(userAction: .addedNewItem, count: 1),
                UserActionItem(userAction: .createdNewSend, count: 2),
            ]
        )
        let isEligible = await subject.isEligibleForReviewPrompt()
        XCTAssertFalse(
            isEligible,
            "User shouldn't be eligible if none of the user actions was repeated 3 times."
        )
    }
}
