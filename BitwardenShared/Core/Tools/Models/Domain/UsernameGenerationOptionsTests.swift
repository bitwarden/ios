import XCTest

@testable import BitwardenShared

class UsernameGenerationOptionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `PasswordGenerationOptions` can be decoded from a JSON with all values set.
    func test_decode() throws {
        let json = """
        {
          "anonAddyApiAccessToken": "ADDYIO_API_TOKEN",
          "anonAddyDomainName": "bitwarden.com",
          "capitalizeRandomWordUsername": true,
          "catchAllEmailDomain": "bitwarden.com",
          "catchAllEmailType": 0,
          "duckDuckGoApiKey": "DUCKDUCKGO_API_KEY",
          "fastMailApiKey": "FASTMAIL_API_KEY",
          "firefoxRelayApiAccessToken": "FIREFOX_API_TOKEN",
          "forwardEmailApiKey": "FORWARD_EMAIL_API_KEY",
          "forwardEmailDomainName": "example.com",
          "includeNumberRandomWordUsername": true,
          "plusAddressedEmail": "user@bitwarden.com",
          "plusAddressedEmailType": 0,
          "serviceType": 2,
          "simpleLoginApiKey": "SIMPLELOGIN_API_KEY",
          "type": 2
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(UsernameGenerationOptions.self, from: data)
        XCTAssertEqual(
            subject,
            UsernameGenerationOptions(
                anonAddyApiAccessToken: "ADDYIO_API_TOKEN",
                anonAddyDomainName: "bitwarden.com",
                capitalizeRandomWordUsername: true,
                catchAllEmailDomain: "bitwarden.com",
                catchAllEmailType: .random,
                duckDuckGoApiKey: "DUCKDUCKGO_API_KEY",
                fastMailApiKey: "FASTMAIL_API_KEY",
                firefoxRelayApiAccessToken: "FIREFOX_API_TOKEN",
                forwardEmailApiKey: "FORWARD_EMAIL_API_KEY",
                forwardEmailDomainName: "example.com",
                includeNumberRandomWordUsername: true,
                plusAddressedEmail: "user@bitwarden.com",
                plusAddressedEmailType: .random,
                serviceType: .simpleLogin,
                simpleLoginApiKey: "SIMPLELOGIN_API_KEY",
                type: .forwardedEmail
            )
        )
    }

    /// `UsernameGenerationOptions` can be decoded from an empty JSON object.
    func test_decode_empty() throws {
        let data = try XCTUnwrap(#"{}"#.data(using: .utf8))
        let subject = try JSONDecoder().decode(UsernameGenerationOptions.self, from: data)
        XCTAssertEqual(subject, UsernameGenerationOptions())
    }
}
