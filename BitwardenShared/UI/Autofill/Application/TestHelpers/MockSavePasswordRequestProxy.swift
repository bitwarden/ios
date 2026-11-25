@testable import BitwardenShared

// MARK: - MockSavePasswordRequestProxy

class MockSavePasswordRequestProxy: SavePasswordRequestProxy {
    var password: String?

    init(password: String? = nil) {
        self.password = password
    }
}
