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

        await subject.decryptAndProcessCiphersInBatch(
            batchSize: 100,
            ciphers: ciphers,
            preFilter: { _ in true },
            onCipher: onCipherClosure,
        )

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

        await subject.decryptAndProcessCiphersInBatch(
            batchSize: 100,
            ciphers: ciphers,
            preFilter: { _ in true },
            onCipher: onCipherClosure,
        )

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

        await subject.decryptAndProcessCiphersInBatch(
            batchSize: 100,
            ciphers: ciphers,
            preFilter: { _ in true },
            onCipher: onCipherClosure,
        )

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

    /// `decryptAndProcessCiphersInBatch(batchSize:ciphers:preFilter:onCipher:)` applies the preFilter
    /// to exclude ciphers before decryption, reducing the number of ciphers sent to the decrypt method.
    func test_decryptAndProcessCiphersInBatch_withPreFilter() async {
        // Given - 950 ciphers where even IDs should be filtered out
        var ciphers: [Cipher] = []
        for index in 0 ..< 950 {
            ciphers.append(.fixture(id: "\(index)", type: index % 2 == 0 ? .card : .login))
        }

        var decryptedCiphers: [CipherListView] = []
        var onCipherCallCount = 0
        let onCipherClosure: (CipherListView) async throws -> Void = { decryptedCipher in
            onCipherCallCount += 1
            decryptedCiphers.append(decryptedCipher)
        }

        // When - applying preFilter to only include login ciphers (odd IDs)
        let preFilter: (Cipher) throws -> Bool = { cipher in
            cipher.type == .login
        }

        await subject.decryptAndProcessCiphersInBatch(
            batchSize: 100,
            ciphers: ciphers,
            preFilter: preFilter,
            onCipher: onCipherClosure,
        )

        // Then - only 475 ciphers should be decrypted (odd IDs = logins)
        XCTAssertEqual(onCipherCallCount, 475)
        XCTAssertEqual(decryptedCiphers.count, 475)

        // Verify decryption was called 10 times (10 batches)
        let decryptListWithFailuresInvocations = clientService.mockVault.clientCiphers
            .decryptListWithFailuresReceivedCiphersInvocations
        XCTAssertEqual(decryptListWithFailuresInvocations.count, 10)

        // Verify batch sizes after filtering (each batch should have ~50 items instead of 100)
        // First 9 batches: 100 ciphers total, but only 50 pass filter (odd IDs)
        for invocationIndex in 0 ..< 9 {
            XCTAssertEqual(decryptListWithFailuresInvocations[invocationIndex].count, 50)
        }
        // Last batch: 50 ciphers total, only 25 pass filter
        XCTAssertEqual(decryptListWithFailuresInvocations[9].count, 25)

        // Verify that only login ciphers (odd IDs) were decrypted
        XCTAssertTrue(decryptedCiphers.allSatisfy { cipher in
            guard let id = cipher.id, let idInt = Int(id) else { return false }
            return idInt % 2 == 1
        })

        // Verify specific cipher IDs that should have been processed
        let decryptedIds = decryptedCiphers.compactMap(\.id)
        XCTAssertTrue(decryptedIds.contains("1"))
        XCTAssertTrue(decryptedIds.contains("3"))
        XCTAssertTrue(decryptedIds.contains("401"))
        XCTAssertTrue(decryptedIds.contains("949"))

        // Verify specific cipher IDs that should NOT have been processed (even IDs = cards)
        XCTAssertFalse(decryptedIds.contains("0"))
        XCTAssertFalse(decryptedIds.contains("2"))
        XCTAssertFalse(decryptedIds.contains("400"))
        XCTAssertFalse(decryptedIds.contains("948"))
    }
}
