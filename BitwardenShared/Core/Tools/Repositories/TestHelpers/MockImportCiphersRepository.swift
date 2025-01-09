import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockImportCiphersRepository: ImportCiphersRepository {
    var importCiphersResult = InvocationMockerWithThrowingResult<UUID, [ImportedCredentialsResult]>()
        .withResult([])
    var progressReport: Double = 0

    func importCiphers(
        credentialImportToken: UUID,
        onProgress: @MainActor (Double) -> Void
    ) async throws -> [ImportedCredentialsResult] {
        await onProgress(progressReport)
        return try importCiphersResult.invoke(param: credentialImportToken)
    }
}
