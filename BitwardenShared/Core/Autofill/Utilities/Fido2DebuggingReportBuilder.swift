#if DEBUG

import BitwardenSdk
import Foundation

/// Report with traceability about Fido2 flows.
public struct Fido2DebuggingReport {
    var allCredentialsResult: Result<[BitwardenSdk.CipherView], Error>?
    var findCredentialsResult: Result<[BitwardenSdk.CipherView], Error>?
    var getAssertionRequest: GetAssertionRequest?
    var getAssertionResult: Result<GetAssertionResult, Error>?
    var saveCredentialCipher: Result<BitwardenSdk.Cipher, Error>?
}

/// Fido2 builder for debugging report.
public struct Fido2DebuggingReportBuilder {
    /// Builder for Fido2 debugging report.
    public static var builder = Fido2DebuggingReportBuilder()

    var report = Fido2DebuggingReport()

    /// Gets the report for Fido2 debugging.
    /// - Returns: Fido2 report.
    public func getReport() -> Fido2DebuggingReport? {
        report
    }

    mutating func withAllCredentialsResult(_ result: Result<[BitwardenSdk.CipherView], Error>) {
        report.allCredentialsResult = result
    }

    mutating func withFindCredentialsResult(_ result: Result<[BitwardenSdk.CipherView], Error>) {
        report.findCredentialsResult = result
    }

    mutating func withGetAssertionRequest(_ request: GetAssertionRequest) {
        report.getAssertionRequest = request
    }

    mutating func withGetAssertionResult(_ result: Result<GetAssertionResult, Error>) {
        report.getAssertionResult = result
    }

    mutating func withSaveCredentialCipher(_ credential: Result<BitwardenSdk.Cipher, Error>) {
        report.saveCredentialCipher = credential
    }
}

#endif
