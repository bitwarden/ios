import BitwardenKit
import BitwardenKitMocks
@testable import BitwardenShared

// MARK: - MockProfileSwitcherHandler

class MockProfileSwitcherHandler: ProfileSwitcherHandler {
    var allowLockAndLogout: Bool = false
    var profileSwitcherState: ProfileSwitcherState = .empty()
    var profileServices: any ProfileServices
    var shouldHideAddAccount: Bool = false
    var toast: Toast?

    var alertsShown: [Alert] = []
    var authEventsHandled: [AuthEvent] = []
    var dismissProfileSwitcherCalled: Bool = false
    var showAddAccountCalled: Bool = false
    var showProfileSwitcherCalled: Bool = false

    init() {
        self.profileServices = ServiceContainer.withMocks(
            authRepository: MockAuthRepository(),
            errorReporter: MockErrorReporter()
        )
    }

    func dismissProfileSwitcher() {
        dismissProfileSwitcherCalled = true
    }

    func handleAuthEvent(_ authEvent: AuthEvent) async {
        authEventsHandled.append(authEvent)
    }

    func showAddAccount() {
        showAddAccountCalled = true
    }

    func showAlert(_ alert: Alert) {
        alertsShown.append(alert)
    }

    func showProfileSwitcher() {
        showProfileSwitcherCalled = true
    }
}
