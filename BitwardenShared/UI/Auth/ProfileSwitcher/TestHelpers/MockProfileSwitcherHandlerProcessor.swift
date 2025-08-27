@testable import BitwardenShared

class MockProfileSwitcherHandlerProcessor:
    MockProcessor<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>,
    ProfileSwitcherHandler {
    func showProfileSwitcher() {

    }
    
    var alertsShown = [BitwardenShared.Alert]()
    var allowLockAndLogout = true
    var handleAuthEvents = [AuthEvent]()
    var profileSwitcherState: ProfileSwitcherState
    var profileServices: ProfileServices
    var shouldHideAddAccount = false
    var toast: Toast?

    init(services: ProfileServices, state: ProfileSwitcherState) {
        profileSwitcherState = state
        profileServices = services
        super.init(state: state)
    }

    func handleAuthEvent(_ authEvent: BitwardenShared.AuthEvent) async {
        handleAuthEvents.append(authEvent)
    }

    func showAddAccount() {}

    func showAlert(_ alert: BitwardenShared.Alert) {
        alertsShown.append(alert)
    }
}
