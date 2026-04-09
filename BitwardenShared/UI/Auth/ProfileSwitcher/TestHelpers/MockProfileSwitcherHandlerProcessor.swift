import BitwardenKit
import BitwardenKitMocks
@testable import BitwardenShared

class MockProfileSwitcherHandlerProcessor:
    MockProcessor<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>,
    ProfileSwitcherHandler {
    var alertsShown = [BitwardenKit.Alert]()
    var allowLockAndLogout = true
    var dismissProfileSwitcherCalled = false
    var handleAuthEvents = [AuthEvent]()
    var profileSwitcherState: ProfileSwitcherState
    var profileServices: ProfileServices
    var shouldHideAddAccount = false
    var showProfileSwitcherCalled = false
    var toast: Toast?

    init(services: ProfileServices, state: ProfileSwitcherState) {
        profileSwitcherState = state
        profileServices = services
        super.init(state: state)
    }

    func dismissProfileSwitcher() {
        dismissProfileSwitcherCalled = true
    }

    func handleAuthEvent(_ authEvent: BitwardenShared.AuthEvent) async {
        handleAuthEvents.append(authEvent)
    }

    func showAddAccount() {}

    func showAlert(_ alert: BitwardenKit.Alert) {
        alertsShown.append(alert)
    }

    func showProfileSwitcher() {
        showProfileSwitcherCalled = true
    }
}
