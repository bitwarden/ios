import BitwardenKit
import BitwardenKitMocks
import Combine
@testable import BitwardenShared

class MockProfileSwitcherHandlerProcessor:
    Processor,
    ProfileSwitcherHandler {
    var alertsShown = [BitwardenShared.Alert]()
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
//        super.init(state: state)
        stateSubject = CurrentValueSubject(state)
    }

    func dismissProfileSwitcher() {
        dismissProfileSwitcherCalled = true
    }

    func handleAuthEvent(_ authEvent: BitwardenShared.AuthEvent) async {
        handleAuthEvents.append(authEvent)
    }

    func showAddAccount() {}

    func showAlert(_ alert: BitwardenShared.Alert) {
        alertsShown.append(alert)
    }

    func showProfileSwitcher() {
        showProfileSwitcherCalled = true
    }

    public var dispatchedActions = [ProfileSwitcherAction]()
    public var effects: [ProfileSwitcherEffect] = []
    let stateSubject: CurrentValueSubject<ProfileSwitcherState, Never>

    public var state: ProfileSwitcherState {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    public var statePublisher: AnyPublisher<ProfileSwitcherState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

//    public init(state: ProfileSwitcherState) {
//        stateSubject = CurrentValueSubject(state)
//    }
//
    public func receive(_ action: ProfileSwitcherAction) {
        dispatchedActions.append(action)
    }

    public func perform(_ effect: ProfileSwitcherEffect) async {
        effects.append(effect)
    }
}
