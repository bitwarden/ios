import WatchConnectivity

@testable import BitwardenShared

class MockWatchService: WatchService {
    var isSupportedValue: Bool = false

    func isSupported() -> Bool {
        isSupportedValue
    }
}
