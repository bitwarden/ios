// swiftlint:disable:this file_name

extension Set<String> {
    /// Returns a set of unique cipher IDs to use as the cipher IDs of a collection or folder.
    ///
    /// - Parameters:
    ///   - count: The number of unique cipher IDs to generate.
    ///   - prefix: A prefix for the generated IDs, used to keep IDs unique across collections or folders.
    /// - Returns: A set containing `count` unique cipher IDs.
    ///
    static func cipherIds(_ count: Int, prefix: String) -> Set<String> {
        Set((0 ..< count).map { "\(prefix)-cipher-\($0)" })
    }
}
