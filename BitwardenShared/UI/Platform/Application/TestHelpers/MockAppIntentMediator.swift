import BitwardenSdk

@testable import BitwardenShared

class MockAppIntentMediator: AppIntentMediator {
    var canRunAppIntentsResult = false
    var generatePassphraseCalled = false
    var generatePassphraseResult: Result<String, Error> = .success("this-is-a-test-passphrase")
    var lockAllUsersCalled = false
    var logoutAllUsersCalled = false
    var openGeneratorCalled = false

    func canRunAppIntents() async -> Bool {
        canRunAppIntentsResult
    }

    func generatePassphrase(settings: BitwardenSdk.PassphraseGeneratorRequest) async throws -> String {
        generatePassphraseCalled = true
        return try generatePassphraseResult.get()
    }

    func lockAllUsers() async throws {
        lockAllUsersCalled = true
    }

    func logoutAllUsers() async throws {
        logoutAllUsersCalled = true
    }

    func openGenerator() async {
        openGeneratorCalled = true
    }
}
