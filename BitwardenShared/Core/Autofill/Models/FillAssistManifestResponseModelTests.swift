import BitwardenKit
import Foundation
import Testing

@testable import BitwardenShared

// MARK: - FillAssistManifestResponseModelTests

struct FillAssistManifestResponseModelTests {
    // MARK: Tests

    /// `init(from:)` decodes all top-level fields and nested map entries correctly.
    @Test
    func decode() throws {
        let json = """
        {
            "buildId": "v20260611.1",
            "gitSha": "ef5022c3cbd8ea198bf7cb497d71320ed722ae23",
            "maps": {
                "forms": {
                    "v1": {
                        "cid": "sha256:3b68ed123425a334166b378bec1ecd0bfab232c21667725b8710d9b35c98f26a",
                        "filename": "forms.v1.json",
                        "schema": "forms.v1.schema.json"
                    }
                }
            },
            "timestamp": "2026-06-11T14:29:32.184Z"
        }
        """
        let model = try JSONDecoder.pascalOrSnakeCaseDecoder.decode(
            FillAssistManifestResponseModel.self,
            from: Data(json.utf8),
        )

        var dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedTimestamp = try #require(dateFormatter.date(from: "2026-06-11T14:29:32.184Z"))
        #expect(model.buildId == "v20260611.1")
        #expect(model.gitSha == "ef5022c3cbd8ea198bf7cb497d71320ed722ae23")
        #expect(model.timestamp == expectedTimestamp)

        let formsV1 = try #require(model.maps["forms"]?["v1"])
        #expect(formsV1.filename == "forms.v1.json")
        #expect(formsV1.schema == "forms.v1.schema.json")
        #expect(formsV1.cid == "sha256:3b68ed123425a334166b378bec1ecd0bfab232c21667725b8710d9b35c98f26a")
        #expect(formsV1.deprecated == nil)
    }

    /// `init(from:)` decodes the `deprecated` flag when present.
    @Test
    func decode_deprecated() throws {
        let json = """
        {
            "buildId": "v20260611.1",
            "gitSha": "abc123",
            "maps": {
                "forms": {
                    "v0": {
                        "cid": "sha256:0000000000000000000000000000000000000000000000000000000000000000",
                        "deprecated": true,
                        "filename": "forms.v0.json",
                        "schema": "forms.v0.schema.json"
                    }
                }
            },
            "timestamp": "2026-06-11T14:29:32.184Z"
        }
        """
        let model = try JSONDecoder.pascalOrSnakeCaseDecoder.decode(
            FillAssistManifestResponseModel.self,
            from: Data(json.utf8),
        )

        let formsV0 = try #require(model.maps["forms"]?["v0"])
        #expect(formsV0.deprecated == true)
    }
}
