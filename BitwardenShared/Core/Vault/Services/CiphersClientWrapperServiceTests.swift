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
        XCTAssertEqual(clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations.count, 10)
        for invocationIndex in 1 ..< 8 {
            XCTAssertEqual(
                clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations[invocationIndex].count,
                100
            )
        }
        XCTAssertEqual(clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations[9].count, 50)
        XCTAssertEqual(clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations[0][40].id, "40")
        XCTAssertEqual(clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations[4][0].id, "400")
        XCTAssertEqual(clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations[9][20].id, "920")
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
            onCipherCallCount += 1
            decryptedCiphers.append(decryptedCipher)
        }

        clientService.mockVault.clientCiphers.decryptListErrorWhenCiphers = { ciphers in
            ciphers.contains(where: { $0.id == "240" })
                ? BitwardenTestError.example
                : nil
        }

        await subject.decryptAndProcessCiphersInBatch(batchSize: 100, ciphers: ciphers, onCipher: onCipherClosure)

        XCTAssertEqual(onCipherCallCount, 850)
        XCTAssertEqual(clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations.count, 9)
        for invocationIndex in 1 ..< 7 {
            XCTAssertEqual(
                clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations[invocationIndex].count,
                100
            )
        }
        XCTAssertEqual(clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations[8].count, 50)
        XCTAssertEqual(clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations[0][40].id, "40")
        XCTAssertEqual(clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations[3][0].id, "400")
        XCTAssertEqual(clientService.mockVault.clientCiphers.decryptListReceivedCiphersInvocations[8][20].id, "920")
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }
}
