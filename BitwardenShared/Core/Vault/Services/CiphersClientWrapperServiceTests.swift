import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - CiphersClientWrapperServiceTests

class CiphersClientWrapperServiceTests: BitwardenTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var subject: CiphersClientWrapperService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        subject = DefaultCiphersClientWrapperService(clientService: clientService, errorReporter: errorReporter)
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `decryptAndProcessCiphersInBatch(batchSize:ciphers:onCipher:)` decrypts ciphers in batches by the size
    /// and executes the `onCipher` closure per each decrypted cipher.
    func test_decryptAndProcessCiphersInBatch() async {
        var ciphers: [Cipher] = []
        var decryptedCiphers: [CipherListView] = []
        for index in 0 ..< 950 {
            ciphers.append(.fixture(id: "\(index)"))
        }
        var onCipherCallCount = 0
        let onCipherClosure: (CipherListView) async throws -> Void = { decryptedCipher in
            onCipherCallCount += 1
            decryptedCiphers.append(decryptedCipher)
        }

        await subject.decryptAndProcessCiphersInBatch(batchSize: 100, ciphers: ciphers, onCipher: onCipherClosure)

        XCTAssertEqual(onCipherCallCount, 950)
        let decryptListWithFailuresInvocations = clientService.mockVault.clientCiphers
            .decryptListWithFailuresReceivedCiphersInvocations
        XCTAssertEqual(decryptListWithFailuresInvocations.count, 10)
        for invocationIndex in 0 ..< 9 {
            XCTAssertEqual(decryptListWithFailuresInvocations[invocationIndex].count, 100)
        }
        XCTAssertEqual(decryptListWithFailuresInvocations[9].count, 50)
        XCTAssertEqual(decryptListWithFailuresInvocations[0][40].id, "40")
        XCTAssertEqual(decryptListWithFailuresInvocations[4][0].id, "400")
        XCTAssertEqual(decryptListWithFailuresInvocations[9][20].id, "920")
    }

    /// `decryptAndProcessCiphersInBatch(batchSize:ciphers:onCipher:)` decrypts ciphers in batches
    /// by the size and converts any failures to `CipherListView`s which can be identified by
    /// the `isDecryptionFailure` property.
    func test_decryptAndProcessCiphersInBatch_withFailures() async {
        let ciphers: [Cipher] = (0 ..< 950).map { Cipher.fixture(id: "\($0)") }
        var decryptedCiphers: [CipherListView] = []
        var onCipherCallCount = 0
        let onCipherClosure: (CipherListView) async throws -> Void = { decryptedCipher in
            onCipherCallCount += 1
            decryptedCiphers.append(decryptedCipher)
        }
        clientService.mockVault.clientCiphers.decryptListWithFailuresResultClosure = { ciphers in
            let successes = ciphers.filter { $0.id != "240" }.map { CipherListView(cipher: $0) }
            let failures = ciphers.filter { $0.id == "240" }
            return DecryptCipherListResult(successes: successes, failures: failures)
        }

        await subject.decryptAndProcessCiphersInBatch(batchSize: 100, ciphers: ciphers, onCipher: onCipherClosure)

        XCTAssertEqual(onCipherCallCount, 950)
        let decryptListWithFailuresInvocations = clientService.mockVault.clientCiphers
            .decryptListWithFailuresReceivedCiphersInvocations
        XCTAssertEqual(decryptListWithFailuresInvocations.count, 10)
        for invocationIndex in 0 ..< 9 {
            XCTAssertEqual(decryptListWithFailuresInvocations[invocationIndex].count, 100)
        }
        XCTAssertEqual(decryptListWithFailuresInvocations[9].count, 50)
        XCTAssertEqual(decryptListWithFailuresInvocations[0][40].id, "40")
        XCTAssertEqual(decryptListWithFailuresInvocations[4][0].id, "400")
        XCTAssertEqual(decryptListWithFailuresInvocations[9][20].id, "920")

        for cipherListView in decryptedCiphers {
            XCTAssertEqual(cipherListView.isDecryptionFailure, cipherListView.id == "240")
        }
    }

    /// `decryptAndProcessCiphersInBatch(batchSize:ciphers:onCipher:)` decrypts ciphers in batches
    /// by the size but throws and it gets logged continuing with the others.
    func test_decryptAndProcessCiphersInBatch_throwsAndLogs() async {
        var ciphers: [Cipher] = []
        var decryptedCiphers: [CipherListView] = []
        for index in 0 ..< 950 {
            ciphers.append(.fixture(id: "\(index)"))
        }
        var onCipherCallCount = 0
        let onCipherClosure: (CipherListView) async throws -> Void = { decryptedCipher in
            guard decryptedCipher.id != "200" else {
                throw BitwardenTestError.example
            }

            onCipherCallCount += 1
            decryptedCiphers.append(decryptedCipher)
        }

        await subject.decryptAndProcessCiphersInBatch(batchSize: 100, ciphers: ciphers, onCipher: onCipherClosure)

        XCTAssertEqual(onCipherCallCount, 850)
        let decryptListWithFailuresInvocations = clientService.mockVault.clientCiphers
            .decryptListWithFailuresReceivedCiphersInvocations
        XCTAssertEqual(decryptListWithFailuresInvocations.count, 10)
        for invocationIndex in 0 ..< 9 {
            XCTAssertEqual(decryptListWithFailuresInvocations[invocationIndex].count, 100)
        }
        XCTAssertEqual(decryptListWithFailuresInvocations[9].count, 50)
        XCTAssertEqual(decryptListWithFailuresInvocations[0][40].id, "40")
        XCTAssertEqual(decryptListWithFailuresInvocations[4][0].id, "400")
        XCTAssertEqual(decryptListWithFailuresInvocations[9][20].id, "920")
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }
}
