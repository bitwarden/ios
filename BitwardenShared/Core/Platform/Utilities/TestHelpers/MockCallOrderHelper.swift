/// Helper class to save calls made to mocks, in order.
class MockCallOrderHelper {
    /// An array saving the calls in order.
    var callOrder: [String] = []

    /// Records a call to a method.
    /// - Parameter methodName: The method name to record.
    func recordCall(_ methodName: String) {
        callOrder.append(methodName)
    }

    /// Resets the saved calls so they are empty.
    func reset() {
        callOrder.removeAll()
    }
}
