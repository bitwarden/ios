import XCTest

@testable import BitwardenShared

// MARK: - CreateAccountProcessorTests

class CreateAccountProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var coordinator: MockCoordinator<AuthRoute>!
    var subject: CreateAccountProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        client = MockHTTPClient()
        coordinator = MockCoordinator<AuthRoute>()

        let state = CreateAccountState()
        subject = CreateAccountProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(httpClient: client),
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_dismiss() {
        subject.receive(.dismiss)
        XCTAssertTrue(coordinator.routes.last == .dismiss)
    }

    /// `perform(_:)` with `.createAccount` creates the user's account.
    func test_perform_createAccount() async {
        client.result = .httpSuccess(testData: .createAccountSuccess)
        subject.state.isCheckDataBreachesToggleOn = true
        subject.state.isTermsAndPrivacyToggleOn = true

        await subject.perform(.createAccount)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests.first?.body, nil)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/da39a"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register"))
    }

    /// `receive(_:)` with `.emailTextChanged(_:)` updates the state to reflect the change.
    func test_receive_emailTextChanged() {
        subject.state.emailText = ""
        XCTAssertTrue(subject.state.emailText.isEmpty)

        subject.receive(.emailTextChanged("updated email"))
        XCTAssertTrue(subject.state.emailText == "updated email")
    }

    /// `receive(_:)` with `.passwordHintTextChanged(_:)` updates the state to reflect the change.
    func test_receive_passwordHintTextChanged() {
        subject.state.passwordHintText = ""
        XCTAssertTrue(subject.state.passwordHintText.isEmpty)

        subject.receive(.passwordHintTextChanged("updated hint"))
        XCTAssertTrue(subject.state.passwordHintText == "updated hint")
    }

    /// `receive(_:)` with `.passwordTextChanged(_:)` updates the state to reflect the change.
    func test_receive_passwordTextChanged() {
        subject.state.passwordText = ""
        XCTAssertTrue(subject.state.passwordText.isEmpty)

        subject.receive(.passwordTextChanged("updated password"))
        XCTAssertTrue(subject.state.passwordText == "updated password")
    }

    /// `receive(_:)` with `.retypePasswordTextChanged(_:)` updates the state to reflect the change.
    func test_receive_retypePasswordTextChanged() {
        subject.state.retypePasswordText = ""
        XCTAssertTrue(subject.state.retypePasswordText.isEmpty)

        subject.receive(.retypePasswordTextChanged("updated re-type"))
        XCTAssertTrue(subject.state.retypePasswordText == "updated re-type")
    }

    /// `receive(_:)` with `.toggleCheckDataBreaches(_:)` updates the state to reflect the change.
    func test_receive_toggleCheckDataBreaches() {
        subject.receive(.toggleCheckDataBreaches(false))
        XCTAssertFalse(subject.state.isCheckDataBreachesToggleOn)

        subject.receive(.toggleCheckDataBreaches(true))
        XCTAssertTrue(subject.state.isCheckDataBreachesToggleOn)
    }

    /// `receive(_:)` with `.toggleTermsAndPrivacy(_:)` updates the state to reflect the change.
    func test_receive_toggleTermsAndPrivacy() {
        subject.receive(.toggleTermsAndPrivacy(false))
        XCTAssertFalse(subject.state.isTermsAndPrivacyToggleOn)

        subject.receive(.toggleTermsAndPrivacy(true))
        XCTAssertTrue(subject.state.isTermsAndPrivacyToggleOn)
    }
}
