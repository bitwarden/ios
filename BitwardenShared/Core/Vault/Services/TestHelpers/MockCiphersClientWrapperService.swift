// swiftlint:disable identifier_name

import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

class MockCiphersClientWrapperService: CiphersClientWrapperService {
    var decryptAndProcessCiphersInBatchBatchSize: Int?
    var decryptAndProcessCiphersInBatchCiphers: [Cipher] = []
    /// The `CipherListView` to be used in the `onCipher` closure
    /// to be evaluated in the `decryptAndProcessCiphersInBatch` function.
    var decryptAndProcessCiphersInBatchOnCipherParameterToPass: BitwardenSdk.CipherListView?
    /// The error thrown by the `onCipher` closure in the `decryptAndProcessCiphersInBatch` function.
    var decryptAndProcessCiphersInBatchOnCipherThrownError: Error?
    /// The result by the `preFilter` closure in the `decryptAndProcessCiphersInBatch` function.
    var decryptAndProcessCiphersInBatchPreFilterResult: Result<[Cipher], Error> = .success([])
    /// Counts how many times `preFilter` was called in the `decryptAndProcessCiphersInBatch` function.
    var decryptAndProcessCiphersInBatchPreFilterCallCount: Int = 0
    /// Counts how many times `onCipher` was called in the `decryptAndProcessCiphersInBatch` function.
    var decryptAndProcessCiphersInBatchOnCipherCallCount: Int = 0

    func decryptAndProcessCiphersInBatch(
        batchSize: Int,
        ciphers: [BitwardenSdk.Cipher],
        preFilter: (Cipher) throws -> Bool,
        onCipher: (BitwardenSdk.CipherListView) async throws -> Void,
    ) async {
        decryptAndProcessCiphersInBatchBatchSize = batchSize
        decryptAndProcessCiphersInBatchCiphers = ciphers
        decryptAndProcessCiphersInBatchPreFilterCallCount = 0
        decryptAndProcessCiphersInBatchOnCipherCallCount = 0

        do {
            let filteredCiphers = try ciphers.filter { cipher in
                decryptAndProcessCiphersInBatchPreFilterCallCount += 1
                return try preFilter(cipher)
            }
            decryptAndProcessCiphersInBatchPreFilterResult = .success(filteredCiphers)
        } catch {
            decryptAndProcessCiphersInBatchPreFilterResult = .failure(error)
        }

        if let decryptAndProcessCiphersInBatchOnCipherParameterToPass {
            do {
                decryptAndProcessCiphersInBatchOnCipherCallCount += 1
                try await onCipher(decryptAndProcessCiphersInBatchOnCipherParameterToPass)
            } catch {
                decryptAndProcessCiphersInBatchOnCipherThrownError = error
            }
        }
    }
}

// swiftlint:enable identifier_name
