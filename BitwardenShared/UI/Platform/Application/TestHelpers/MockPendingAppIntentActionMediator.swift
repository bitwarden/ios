@testable import BitwardenShared

class MockPendingAppIntentActionMediator: PendingAppIntentActionMediator {
    var delegate: PendingAppIntentActionMediatorDelegate?
    var executePendingAppIntentActions = false

    func executePendingAppIntentActions() async {
        executePendingAppIntentActions = true
    }

    func setDelegate(_ delegate: PendingAppIntentActionMediatorDelegate) {
        self.delegate = delegate
    }
}
