import BitwardenSdk
import XCTest

@testable import BitwardenShared

class GeneratorDataStoreTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DataStore!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `deleteAllPasswordHistory(userId:)` removes all objects for the specified user.
    func test_deleteAllPasswordHistory() async throws {
        let passwordHistories = [
            PasswordHistory(password: "PASSWORD1", lastUsedDate: Date()),
            PasswordHistory(password: "PASSWORD2", lastUsedDate: Date()),
            PasswordHistory(password: "PASSWORD3", lastUsedDate: Date()),
        ]
        for passwordHistory in passwordHistories {
            try await subject.insertPasswordHistory(userId: "1", passwordHistory: passwordHistory)
            try await subject.insertPasswordHistory(userId: "2", passwordHistory: passwordHistory)
        }

        try await subject.deleteAllPasswordHistory(userId: "1")

        let resultsUser1 = try subject.backgroundContext.fetch(PasswordHistoryData.fetchByUserIdRequest(userId: "1"))
        XCTAssertTrue(resultsUser1.isEmpty)

        let resultsUser2 = try subject.backgroundContext.fetch(PasswordHistoryData.fetchByUserIdRequest(userId: "2"))
        XCTAssertEqual(resultsUser2.count, 3)
    }

    /// deletePasswordHistoryPastLimit(userId:limit:)` deletes any objects older than limit.
    func test_deletePasswordHistoryPastLimit() async throws {
        let passwords = (0 ... 10).map { index in
            // Manually specifying the date as the index value prevents the instances from
            // getting out of order when sorting by the date.
            PasswordHistory(
                password: index.description,
                lastUsedDate: Date(timeIntervalSince1970: Double(index))
            )
        }

        try subject.backgroundContext.performAndWait {
            for password in passwords {
                _ = PasswordHistoryData(context: self.subject.backgroundContext, userId: "1", passwordHistory: password)
            }
            try self.subject.backgroundContext.saveIfChanged()
        }

        try await subject.deletePasswordHistoryPastLimit(userId: "1", limit: 5)

        let fetchRequest = PasswordHistoryData.fetchByUserIdRequest(userId: "1")
        fetchRequest.sortDescriptors = [PasswordHistoryData.sortByLastUsedDateDescending]
        let results = try subject.backgroundContext.fetch(fetchRequest)
        XCTAssertEqual(
            try results.map(PasswordHistory.init),
            passwords.suffix(5).reversed()
        )
    }

    /// `fetchPasswordHistoryMostRecent(userId:)` fetches the most recent password history object.
    func test_fetchPasswordHistoryMostRecent() async throws {
        let passwords = (0 ... 10).map { index in
            // Manually specifying the date as the index value prevents the instances from
            // getting out of order when sorting by the date.
            PasswordHistory(
                password: index.description,
                lastUsedDate: Date(timeIntervalSince1970: Double(index))
            )
        }

        try subject.backgroundContext.performAndWait {
            for password in passwords {
                _ = PasswordHistoryData(context: self.subject.backgroundContext, userId: "1", passwordHistory: password)
            }
            try self.subject.backgroundContext.saveIfChanged()
        }

        let result = try await subject.fetchPasswordHistoryMostRecent(userId: "1")
        XCTAssertEqual(result, passwords.last)
    }

    /// `insertPasswordHistory(userId:passwordHistory:)` inserts the password history data into the
    /// data store for the user.
    func test_insertPasswordHistory() async throws {
        let passwordHistory1 = PasswordHistory(password: "PASSWORD1", lastUsedDate: Date())
        let passwordHistory2 = PasswordHistory(password: "PASSWORD2", lastUsedDate: Date())
        try await subject.insertPasswordHistory(
            userId: "1",
            passwordHistory: passwordHistory1
        )
        let results = try subject.backgroundContext.fetch(PasswordHistoryData.fetchByUserIdRequest(userId: "1"))
        try XCTAssertEqual(results.map(PasswordHistory.init), [passwordHistory1])

        try await subject.insertPasswordHistory(
            userId: "1",
            passwordHistory: passwordHistory2
        )
        let resultsUpdated = try subject.backgroundContext.fetch(PasswordHistoryData.fetchByUserIdRequest(userId: "1"))
        try XCTAssertEqual(resultsUpdated.map(PasswordHistory.init), [passwordHistory1, passwordHistory2])
    }

    /// `passwordHistoryPublisher(userId:)` returns a publisher for a user's password history objects.
    func test_passwordHistoryPublisher() async throws {
        var publishedValues = [[PasswordHistory]]()
        let publisher = subject.passwordHistoryPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { values in
                    publishedValues.append(values)
                }
            )
        defer { publisher.cancel() }

        let passwordHistory1 = PasswordHistory(password: "PASSWORD1", lastUsedDate: Date())
        try await subject.insertPasswordHistory(userId: "1", passwordHistory: passwordHistory1)

        let passwordHistoryOther = PasswordHistory(password: "PASSWORD_OTHER", lastUsedDate: Date())
        try await subject.insertPasswordHistory(userId: "2", passwordHistory: passwordHistoryOther)

        let passwordHistory2 = PasswordHistory(password: "PASSWORD2", lastUsedDate: Date())
        try await subject.insertPasswordHistory(userId: "1", passwordHistory: passwordHistory2)

        waitFor { publishedValues.count == 3 }
        XCTAssertTrue(publishedValues[0].isEmpty)
        XCTAssertEqual(publishedValues[1], [passwordHistory1])
        XCTAssertEqual(publishedValues[2], [passwordHistory2, passwordHistory1])
    }
}
