import BitwardenSdk
import Foundation
import TestHelpers

@testable import BitwardenShared

class MockImportCiphersRepository: ImportCiphersRepository {
    var importCiphersResult = InvocationMockerWithThrowingResult<UUID, [CXFCredentialsResult]>()
        .withResult([])
    var progressReport: Double = 0

    func importCiphers(
        credentialImportToken: UUID,
        onProgress: @MainActor (Double) -> Void,
    ) async throws -> [CXFCredentialsResult] {
        await onProgress(progressReport)
        return try importCiphersResult.invoke(param: credentialImportToken)
    }
}
