import Foundation
import Security
import XCTest

// MARK: - TestIdentity

/// A self-signed RSA test identity for tests that need a `SecIdentity`.
enum TestIdentity {
    /// Creates a `SecIdentity` from a pre-generated self-signed test PKCS#12 (password: "testpassword").
    static func make() throws -> SecIdentity {
        // swiftlint:disable:next line_length
        let p12Base64 = "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"
        let p12Data = try XCTUnwrap(Data(base64Encoded: p12Base64))
        var importResult: CFArray?
        let status = SecPKCS12Import(
            p12Data as CFData,
            [kSecImportExportPassphrase: "testpassword"] as CFDictionary,
            &importResult,
        )
        guard status == errSecSuccess,
              let items = importResult as? [[String: Any]],
              let identityRef = items.first?[kSecImportItemIdentity as String] else {
            throw XCTestError(
                .failureWhileWaiting,
                userInfo: [NSLocalizedDescriptionKey: "Failed to import test identity"],
            )
        }
        // swiftlint:disable:next force_cast
        return identityRef as! SecIdentity
    }
}
