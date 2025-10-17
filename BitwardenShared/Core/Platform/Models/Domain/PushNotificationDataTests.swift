import XCTest

@testable import BitwardenShared

class PushNotificationDataTests: BitwardenTestCase {
    /// `data` decodes the payload as expected.
    func test_data() {
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

        let data: SyncCipherNotification? = subject.data()

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

    /// `data` returns nil if there was a problem decoding the payload.
    func test_data_nil() {
        let subject = PushNotificationData(contextId: nil, payload: "gibberish", type: .syncCipherCreate)

        let data: SyncCipherNotification? = subject.data()

        XCTAssertNil(data)
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

        let data: LogoutNotification = try XCTUnwrap(subject.data())
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

        let data: LogoutNotification = try XCTUnwrap(subject.data())
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

        let data: LogoutNotification = try XCTUnwrap(subject.data())
        XCTAssertEqual(data, LogoutNotification(
            date: Date(year: 2025, month: 10, day: 1),
            reason: .unknown,
            userId: "12345",
        ))
    }
}
