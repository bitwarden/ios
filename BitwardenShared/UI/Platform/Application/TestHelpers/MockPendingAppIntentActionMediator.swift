@testable import BitwardenShared

class MockPendingAppIntentActionMediator: PendingAppIntentActionMediator {
    var delegate: PendingAppIntentActionMediatorDelegate?
    var executePendingAppIntentActionsCalled = false

    func executePendingAppIntentActions() async {
        executePendingAppIntentActionsCalled = true
    }

    func setDelegate(_ delegate: PendingAppIntentActionMediatorDelegate) {
        self.delegate = delegate
    }
}
