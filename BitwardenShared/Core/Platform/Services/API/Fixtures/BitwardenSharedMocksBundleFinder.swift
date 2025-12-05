import Foundation

class BitwardenSharedMocksBundleFinder {
    static let bundle = Bundle(for: BitwardenSharedMocksBundleFinder.self)
}

public extension Bundle {
    /// The `Bundle` instance for the `BitwardenSharedMocks` target.
    static let bitwardenSharedMocks = BitwardenSharedMocksBundleFinder.bundle
}
