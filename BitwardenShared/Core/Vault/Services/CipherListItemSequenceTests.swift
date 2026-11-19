import BitwardenKitMocks
import BitwardenSdk
import BitwardenSdkMocks
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - CipherListItemSequenceTests

struct CipherListItemSequenceTests {
    // MARK: Properties

    let stream: MockCipherListStreamProtocol
    let subject: CipherListItemSequence

    // MARK: Initialization

    init() {
        stream = MockCipherListStreamProtocol()
        subject = CipherListItemSequence(stream: stream)
    }

    // MARK: Tests

    /// Iterating the sequence returns the items of every chunk in order, asking for the next chunk
    /// only when the previous one is used up, and ends when the stream returns `nil`.
    @Test
    func iterate_flattensChunks() async throws {
        var chunks: [[CipherListItem]?] = [
            [decrypted("1"), failed("2")],
            [],
            [decrypted("3")],
            nil,
        ]
        stream.nextChunkClosure = { chunks.removeFirst() }

        var iterator = subject.makeAsyncIterator()
        let first = try await iterator.next()
        #expect(first.map(id) == "1")
        #expect(stream.nextChunkCallsCount == 1)

        var ids = [first.map(id)]
        while let item = try await iterator.next() {
            ids.append(id(of: item))
        }

        #expect(ids == ["1", "2", "3"])
        #expect(stream.nextChunkCallsCount == 4)

        let afterEnd = try await iterator.next()
        #expect(afterEnd == nil)
        #expect(stream.nextChunkCallsCount == 4)
    }

    /// Iterating the sequence returns no items when the stream has none.
    @Test
    func iterate_empty() async throws {
        stream.nextChunkReturnValue = nil

        var ids: [String?] = []
        for try await item in subject {
            ids.append(id(of: item))
        }

        #expect(ids.isEmpty)
        #expect(stream.nextChunkCallsCount == 1)
    }

    /// Iterating the sequence throws the error of the stream after the items before it, and then
    /// ends.
    @Test
    func iterate_error() async throws {
        var chunks: [[CipherListItem]?] = [[decrypted("1")]]
        stream.nextChunkClosure = {
            guard !chunks.isEmpty else { throw BitwardenTestError.example }
            return chunks.removeFirst()
        }

        var iterator = subject.makeAsyncIterator()
        let first = try await iterator.next()
        #expect(first.map(id) == "1")

        await #expect(throws: BitwardenTestError.example) {
            _ = try await iterator.next()
        }

        let afterError = try await iterator.next()
        #expect(afterError == nil)
        #expect(stream.nextChunkCallsCount == 2)
    }

    /// Iterating the sequence throws `CancellationError` once the task is cancelled, without
    /// returning the rest of the chunk or asking for another one.
    @Test
    func iterate_cancelled() async throws {
        stream.nextChunkReturnValue = [decrypted("1"), decrypted("2")]
        let sequence = subject

        let task = Task {
            var iterator = sequence.makeAsyncIterator()
            let first = try await iterator.next()
            withUnsafeCurrentTask { $0?.cancel() }
            do {
                _ = try await iterator.next()
                Issue.record("Expected a CancellationError")
            } catch {
                #expect(error is CancellationError)
            }
            return first.map(id)
        }

        let first = try await task.value
        #expect(first == "1")
        #expect(stream.nextChunkCallsCount == 1)
    }

    // MARK: Private

    /// A decrypted item with the given cipher ID.
    private func decrypted(_ id: String) -> CipherListItem {
        .decrypted(view: .fixture(id: id))
    }

    /// An item that failed to decrypt, with the given cipher ID.
    private func failed(_ id: String) -> CipherListItem {
        .failed(cipher: .fixture(id: id))
    }

    /// The cipher ID of an item.
    private func id(of item: CipherListItem) -> String? {
        switch item {
        case let .decrypted(view):
            view.id
        case let .failed(cipher):
            cipher.id
        }
    }
}
