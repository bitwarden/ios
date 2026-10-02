import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared

// MARK: - SendEncryptionVersionTests

struct SendEncryptionVersionTests {
    // MARK: Tests

    /// `defaultValue` is `.v1`.
    @Test
    func defaultValue() {
        #expect(SendEncryptionVersion.defaultValue == .v1)
    }

    /// `init(from:)` decodes unknown values to `.unknown`.
    @Test
    func init_decoder_unknownValues() throws {
        #expect(try JSONDecoder().decode(SendEncryptionVersion.self, from: Data("99".utf8)) == .unknown)
        #expect(try JSONDecoder().decode(SendEncryptionVersion.self, from: Data("-5".utf8)) == .unknown)
    }

    /// `init(from:)` decodes known values to the matching encryption version.
    @Test
    func init_decoder_validValues() throws {
        #expect(try JSONDecoder().decode(SendEncryptionVersion.self, from: Data("1".utf8)) == .v1)
        #expect(try JSONDecoder().decode(SendEncryptionVersion.self, from: Data("-1".utf8)) == .unknown)
    }

    /// `init(encryptionType:)` correctly initializes from SDK `SendEncryptionType`.
    @Test
    func init_encryptionType() {
        #expect(SendEncryptionVersion(encryptionType: .v1) == .v1)
    }

    /// `rawValue` returns the correct integer for each encryption version.
    @Test
    func rawValue() {
        #expect(SendEncryptionVersion.unknown.rawValue == -1)
        #expect(SendEncryptionVersion.v1.rawValue == 1)
    }

    /// `sdkEncryptionType` returns the correct SDK `SendEncryptionType` for each encryption version.
    @Test
    func sdkEncryptionType() {
        #expect(SendEncryptionVersion.unknown.sdkEncryptionType == nil)
        #expect(SendEncryptionVersion.v1.sdkEncryptionType == .v1)
    }
}
