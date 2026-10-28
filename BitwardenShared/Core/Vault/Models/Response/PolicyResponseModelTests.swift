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

        #expect(subject.map(\.type) == [.disableSend, nil])
        #expect(subject[1].$type == .unknown(99))
    }

    /// `init(from:)` decodes a policy with a missing or `null` type as a `nil` type, with no raw
    /// value.
    @Test
    func decode_missingOrNullType() throws {
        let json = """
        [
          {"enabled": true, "id": "1", "organizationId": "org-1"},
          {"enabled": true, "id": "2", "organizationId": "org-1", "type": null}
        ]
        """

        let subject = try JSONDecoder().decode([PolicyResponseModel].self, from: Data(json.utf8))

        #expect(subject.map(\.type) == [nil, nil])
        #expect(subject.map(\.$type) == [nil, nil])
    }

    /// `encode(to:)` encodes an unrecognized policy type with its original raw value.
    @Test
    func encode_unknownType_roundTripsRawValue() throws {
        var subject = PolicyResponseModel.fixture()
        subject.$type = .unknown(99)

        let data = try JSONEncoder().encode(subject)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["type"] as? Int == 99)
        #expect(try JSONDecoder().decode(PolicyResponseModel.self, from: data) == subject)
    }
}
