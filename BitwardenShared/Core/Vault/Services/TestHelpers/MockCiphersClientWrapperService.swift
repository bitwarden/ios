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

    func decryptAndProcessCiphersInBatch(
        batchSize: Int,
        ciphers: [BitwardenSdk.Cipher],
        onCipher: (BitwardenSdk.CipherListView) async throws -> Void
    ) async {
        decryptAndProcessCiphersInBatchBatchSize = batchSize
        decryptAndProcessCiphersInBatchCiphers = ciphers
        if let decryptAndProcessCiphersInBatchOnCipherParameterToPass {
            do {
                try await onCipher(decryptAndProcessCiphersInBatchOnCipherParameterToPass)
            } catch {
                decryptAndProcessCiphersInBatchOnCipherThrownError = error
            }
        }
    }
}

// swiftlint:enable identifier_name
