import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockImportCiphersRepository: ImportCiphersRepository {
    var importCiphersResult = InvocationMockerWithThrowingResult<UUID, [ImportedCredentialsResult]>()
        .withResult([])

    func importCiphers(
        credentialImportToken: UUID,
        progressDelegate: ProgressDelegate
    ) async throws -> [ImportedCredentialsResult] {
        try importCiphersResult.invoke(param: credentialImportToken)
    }
}
