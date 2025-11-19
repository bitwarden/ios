@testable import BitwardenShared

class MockChangeKdfService: ChangeKdfService {
    var needsKdfUpdateToMinimumsCalled = false
    var needsKdfUpdateToMinimumsResult = false

    var updateKdfToMinimumsCalled = false
    var updateKdfToMinimumsPassword: String?
    var updateKdfToMinimumsResult: Result<Void, Error> = .success(())

    func needsKdfUpdateToMinimums() async -> Bool {
        needsKdfUpdateToMinimumsCalled = true
        return needsKdfUpdateToMinimumsResult
    }

    func updateKdfToMinimums(password: String) async throws {
        updateKdfToMinimumsCalled = true
        updateKdfToMinimumsPassword = password
        try updateKdfToMinimumsResult.get()
    }
}
