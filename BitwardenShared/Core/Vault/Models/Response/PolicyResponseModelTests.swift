import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct PolicyResponseModelTests {
    // MARK: Tests

    /// `init(from:)` decodes a list of policies containing a policy type the app doesn't
    /// recognize without failing, preserving the unrecognized raw value.
    @Test
    func decode_unknownType() throws {
        let json = """
        [
          {"enabled": true, "id": "1", "organizationId": "org-1", "type": 6},
          {"enabled": true, "id": "2", "organizationId": "org-1", "type": 99}
        ]
        """

        let subject = try JSONDecoder().decode([PolicyResponseModel].self, from: Data(json.utf8))

        #expect(subject.map(\.type) == [.known(.disableSend), .unknown(99)])
    }

    /// `encode(to:)` encodes an unrecognized policy type with its original raw value.
    @Test
    func encode_unknownType_roundTripsRawValue() throws {
        let subject = PolicyResponseModel.fixture(type: .unknown(99))

        let data = try JSONEncoder().encode(subject)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["type"] as? Int == 99)
        #expect(try JSONDecoder().decode(PolicyResponseModel.self, from: data) == subject)
    }
}
