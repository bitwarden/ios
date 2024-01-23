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
            type: .syncCipherCreate
        )

        let data: SyncCipherNotification? = subject.data()

        XCTAssertEqual(
            data,
            SyncCipherNotification(
                collectionIds: nil,
                id: "90eeb69a-722f-48be-8ab1-b0df01105e2a",
                organizationId: nil,
                revisionDate: Date(year: 2023, month: 12, day: 21),
                userId: "0efb0a6a-691e-490d-85d4-af5800dd267a"
            )
        )
    }

    /// `data` returns nil if there was a problem decoding the payload.
    func test_data_nil() {
        let subject = PushNotificationData(contextId: nil, payload: "gibberish", type: .syncCipherCreate)

        let data: SyncCipherNotification? = subject.data()

        XCTAssertNil(data)
    }
}
