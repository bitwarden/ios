import XCTest

@testable import BitwardenShared

class PushNotificationDataTests: BitwardenTestCase {
    // MARK: init(userInfo:) Tests

    /// `init(userInfo:)` successfully decodes a `PushNotificationData` from a valid `userInfo` dictionary.
    func test_initUserInfo() throws {
        let userInfo: [AnyHashable: Any] = [
            "data": [
                "contextId": "context-123",
                "payload": "test-payload",
                "type": 1,
            ] as [AnyHashable: Any],
        ]

        let subject = try PushNotificationData(userInfo: userInfo)

        XCTAssertEqual(subject.contextId, "context-123")
        XCTAssertEqual(subject.payload, "test-payload")
        XCTAssertEqual(subject.type, .syncCipherCreate)
    }

    /// `init(userInfo:)` throws `missingDataDictionary` when the `userInfo` dictionary is empty.
    func test_initUserInfo_emptyDictionary() {
        XCTAssertThrowsError(try PushNotificationData(userInfo: [:])) { error in
            guard case PushNotificationDataError.missingDataDictionary = error else {
                XCTFail("Expected PushNotificationDataError.missingDataDictionary, got \(error)")
                return
            }
        }
    }

    /// `init(userInfo:)` throws a decoding error when the `"data"` value cannot be decoded.
    func test_initUserInfo_invalidData() {
        let userInfo: [AnyHashable: Any] = [
            "data": [
                "type": "not-a-number",
            ] as [AnyHashable: Any],
        ]

        XCTAssertThrowsError(try PushNotificationData(userInfo: userInfo)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    /// `init(userInfo:)` throws `missingDataDictionary` when the `"data"` key is absent.
    func test_initUserInfo_missingDataKey() {
        let userInfo: [AnyHashable: Any] = ["other": "value"]

        XCTAssertThrowsError(try PushNotificationData(userInfo: userInfo)) { error in
            guard case PushNotificationDataError.missingDataDictionary = error else {
                XCTFail("Expected PushNotificationDataError.missingDataDictionary, got \(error)")
                return
            }
        }
    }

    // MARK: data Tests

    /// `data` decodes the payload as expected.
    func test_data() throws {
        let subject = PushNotificationData(
            contextId: nil,
            payload: """
            {
            "Id": "90eeb69a-722f-48be-8ab1-b0df01105e2a",
            "UserId": "0efb0a6a-691e-490d-85d4-af5800dd267a",
            "RevisionDate": "2023-12-21T00:00:00.000Z"
            }
            """,
            type: .syncCipherCreate,
        )

        let data: SyncCipherNotification = try subject.data()

        XCTAssertEqual(
            data,
            SyncCipherNotification(
                collectionIds: nil,
                id: "90eeb69a-722f-48be-8ab1-b0df01105e2a",
                organizationId: nil,
                revisionDate: Date(year: 2023, month: 12, day: 21),
                userId: "0efb0a6a-691e-490d-85d4-af5800dd267a",
            ),
        )
    }

    /// `data` throws a `PushNotificationDataError` when the payload is `nil`.
    func test_data_payloadNil() throws {
        let subject = PushNotificationData(contextId: nil, payload: nil, type: .syncCipherCreate)

        XCTAssertThrowsError(try subject.data() as SyncCipherNotification) { error in
            guard case let PushNotificationDataError.payloadDecodingFailed(type, underlyingError) = error else {
                XCTFail("Expected PushNotificationDataError.payloadDecodingFailed, got \(error)")
                return
            }
            XCTAssertEqual(type, .syncCipherCreate)
            XCTAssertEqual((underlyingError as NSError).domain, "Data Error")
        }
    }

    /// `data` throws a `PushNotificationDataError` when the payload is an empty string.
    func test_data_payloadEmpty() throws {
        let subject = PushNotificationData(contextId: nil, payload: "", type: .syncCipherCreate)

        XCTAssertThrowsError(try subject.data() as SyncCipherNotification) { error in
            guard case let PushNotificationDataError.payloadDecodingFailed(type, underlyingError) = error else {
                XCTFail("Expected PushNotificationDataError.payloadDecodingFailed, got \(error)")
                return
            }
            XCTAssertEqual(type, .syncCipherCreate)
            XCTAssertEqual((underlyingError as NSError).domain, "Data Error")
        }
    }

    /// `data` throws a `PushNotificationDataError` if there was a problem decoding the payload.
    func test_data_payloadInvalid() throws {
        let subject = PushNotificationData(contextId: nil, payload: "gibberish", type: .syncCipherCreate)

        XCTAssertThrowsError(try subject.data() as SyncCipherNotification) { error in
            guard case let PushNotificationDataError.payloadDecodingFailed(type, underlyingError) = error else {
                XCTFail("Expected PushNotificationDataError.payloadDecodingFailed, got \(error)")
                return
            }
            XCTAssertEqual(type, .syncCipherCreate)
            XCTAssertTrue(underlyingError is DecodingError)
        }
    }

    /// `data()` decodes a logout notification.
    func test_data_logoutNotification() throws {
        let subject = PushNotificationData(
            contextId: nil,
            payload: """
            {
                "Date": "2025-10-01T00:00:00.000Z",
                "UserId": "12345",
            }
            """,
            type: .logOut,
        )

        let data: LogoutNotification = try subject.data()
        XCTAssertEqual(data, LogoutNotification(
            date: Date(year: 2025, month: 10, day: 1),
            reason: .unknown,
            userId: "12345",
        ))
    }

    /// `data()` decodes a logout notification with a reason.
    func test_data_logoutNotification_withReason() throws {
        let subject = PushNotificationData(
            contextId: nil,
            payload: """
            {
                "Date": "2025-10-01T00:00:00.000Z",
                "Reason": 0,
                "UserId": "12345",
            }
            """,
            type: .logOut,
        )

        let data: LogoutNotification = try subject.data()
        XCTAssertEqual(data, LogoutNotification(
            date: Date(year: 2025, month: 10, day: 1),
            reason: .kdfChange,
            userId: "12345",
        ))
    }

    /// `data()` decodes a logout notification with an unknown reason.
    func test_data_logoutNotification_withReasonUnknown() throws {
        let subject = PushNotificationData(
            contextId: nil,
            payload: """
            {
                "Date": "2025-10-01T00:00:00.000Z",
                "Reason": -2,
                "UserId": "12345",
            }
            """,
            type: .logOut,
        )

        let data: LogoutNotification = try subject.data()
        XCTAssertEqual(data, LogoutNotification(
            date: Date(year: 2025, month: 10, day: 1),
            reason: .unknown,
            userId: "12345",
        ))
    }
}
