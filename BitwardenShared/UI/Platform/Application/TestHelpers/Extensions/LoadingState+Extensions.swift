@testable import BitwardenShared

extension LoadingState {
    var wrappedData: T? {
        guard case let .data(value) = self else {
            return nil
        }
        return value
    }
}
