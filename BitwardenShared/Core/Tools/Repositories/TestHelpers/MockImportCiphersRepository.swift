import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockImportCiphersRepository: ImportCiphersRepository {
    var importCiphersResult = InvocationMockerWithThrowingResult<UUID, [ImportedCredentialsResult]>()
        .withResult([])

    func importCiphers(
        credentialImportToken: UUID,
        onProgress: @MainActor (_ progress: Double) -> Void
    ) async throws -> [ImportedCredentialsResult] {
        try importCiphersResult.invoke(param: credentialImportToken)
    }
}
