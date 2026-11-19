import BitwardenSdk

// MARK: - CipherListItemSequence

/// An asynchronous sequence of the ciphers in an SDK `CipherListStream`, one `CipherListItem` at a
/// time, in the order of the cipher repository.
///
/// The SDK reads and decrypts the ciphers a chunk at a time, and the sequence asks for the next
/// chunk only once every item of the previous chunk has been returned, so only one chunk is held
/// in memory at a time.
///
/// The sequence ends when the stream has no more ciphers. It throws the stream's error if the
/// listing fails, for example when the vault is locked, and `CancellationError` if the task that
/// iterates it is cancelled. In both cases, the items returned before were only part of the list.
///
struct CipherListItemSequence: AsyncSequence {
    typealias Element = CipherListItem

    // MARK: Iterator

    /// The iterator of a `CipherListItemSequence`.
    struct Iterator: AsyncIteratorProtocol {
        // MARK: Properties

        /// The items of the current chunk that have not been returned yet.
        private var chunk = [CipherListItem]().makeIterator()

        /// Whether the stream has ended, or failed.
        private var isFinished = false

        /// The SDK stream that reads and decrypts the ciphers.
        private let stream: CipherListStreamProtocol

        // MARK: Initialization

        /// Initializes an `Iterator`.
        ///
        /// - Parameter stream: The SDK stream that reads and decrypts the ciphers.
        ///
        init(stream: CipherListStreamProtocol) {
            self.stream = stream
        }

        // MARK: AsyncIteratorProtocol

        mutating func next() async throws -> CipherListItem? {
            while !isFinished {
                do {
                    try Task.checkCancellation()
                    if let item = chunk.next() {
                        return item
                    }
                    guard let nextChunk = try await stream.nextChunk() else {
                        isFinished = true
                        return nil
                    }
                    chunk = nextChunk.makeIterator()
                } catch {
                    isFinished = true
                    throw error
                }
            }
            return nil
        }
    }

    // MARK: Properties

    /// The SDK stream that reads and decrypts the ciphers.
    let stream: CipherListStreamProtocol

    // MARK: AsyncSequence

    func makeAsyncIterator() -> Iterator {
        Iterator(stream: stream)
    }
}
