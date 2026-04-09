import Foundation

class BitwardenKitMocksBundleFinder {
    static let bundle = Bundle(for: BitwardenKitMocksBundleFinder.self)
}

public extension Bundle {
    /// The bundle for the `BitwardenKitMocks` target.
    static let bitwardenKitMocks = BitwardenKitMocksBundleFinder.bundle
}
