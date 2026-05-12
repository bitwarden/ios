import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import BitwardenShared

struct SerialWorkerTests {
    let subject: SerialWorker

    init() {
        subject = SerialWorker()
    }

    // MARK: Tests - enqueue

    /// `enqueue` executes the provided operation.
    ///
    @Test
    func serialize_executesOperation() async throws {
        var executed = false

        try await subject.enqueue(userId: "u1") {
            executed = true
        }

        #expect(executed)
    }

    /// `enqueue` runs the next operation for the same user even when the previous one threw.
    ///
    @Test
    func serialize_failingPreviousOperation_nextOperationStillRuns() async throws {
        struct TestError: Error, Equatable {}

        await #expect(throws: TestError()) {
            try await subject.enqueue(userId: "u1") { throw TestError() }
        }

        var executed = false
        try await subject.enqueue(userId: "u1") {
            executed = true
        }

        #expect(executed)
    }

    /// `enqueue` runs operations for different users independently.
    ///
    @Test
    func serialize_differentUsers_bothOperationsRun() async throws {
        var u1Ran = false
        var u2Ran = false

        try await subject.enqueue(userId: "u1") { u1Ran = true }
        try await subject.enqueue(userId: "u2") { u2Ran = true }

        #expect(u1Ran)
        #expect(u2Ran)
    }

    /// `enqueue` for the same user runs operations in serial order.
    ///
    @Test
    func serialize_sameUser_operationsRunInSubmissionOrder() async throws {
        // Halt op1 at a CheckedContinuation so op2 can be submitted while op1 is in-flight.
        nonisolated(unsafe) var log: [Int] = []
        nonisolated(unsafe) var op1Continuation: CheckedContinuation<Void, Never>?

        let task1 = Task {
            try await subject.enqueue(userId: "u1") {
                await withCheckedContinuation { cont in
                    op1Continuation = cont
                }
                log.append(1)
            }
        }

        // Suspend until task1 has reached its suspension point inside op1.
        while op1Continuation == nil {
            await Task.yield()
        }

        // Submit op2 while op1 is still in-flight.
        let task2 = Task {
            try await subject.enqueue(userId: "u1") {
                log.append(2)
            }
        }

        // Allow task2 time to register itself in the serializer.
        await Task.yield()
        await Task.yield()

        #expect(log.isEmpty)

        // Unblock op1; op2 must follow.
        op1Continuation!.resume()

        try await task1.value
        try await task2.value

        #expect(log == [1, 2])
    }
}
