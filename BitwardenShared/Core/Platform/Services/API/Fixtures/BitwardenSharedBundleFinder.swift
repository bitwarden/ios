import Foundation

class BitwardenSharedBundleFinder {
    static let bundle = Bundle(for: BitwardenSharedBundleFinder.self)
}

public extension Bundle {
    /// The bundle for the `BitwardenShared` target.
    static let bitwardenShared = BitwardenSharedBundleFinder.bundle
}
