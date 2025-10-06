import BitwardenSdk

@testable import BitwardenShared

class MockMasterPasswordRepromptHelper: MasterPasswordRepromptHelper {
    var repromptForMasterPasswordCipherId: String?
    var repromptForMasterPasswordCipherListView: CipherListView?
    var repromptForMasterPasswordCipherView: CipherView?
    var repromptForMasterPasswordCompletion: (@MainActor () async -> Void)?

    /// Set this to false to complete master password reprompt manually by calling the
    /// `repromptForMasterPasswordCompletion` closure. Otherwise, the completion closure will be
    /// called automatically.
    var repromptForMasterPasswordAutoComplete = true

    func repromptForMasterPasswordIfNeeded(
        cipherId: String,
        completion: @escaping @MainActor () async -> Void,
    ) async {
        repromptForMasterPasswordCipherId = cipherId
        if repromptForMasterPasswordAutoComplete {
            await completion()
        } else {
            repromptForMasterPasswordCompletion = completion
        }
    }

    func repromptForMasterPasswordIfNeeded(
        cipherListView: CipherListView,
        completion: @escaping @MainActor () async -> Void,
    ) async {
        repromptForMasterPasswordCipherListView = cipherListView
        if repromptForMasterPasswordAutoComplete {
            await completion()
        } else {
            repromptForMasterPasswordCompletion = completion
        }
    }

    func repromptForMasterPasswordIfNeeded(
        cipherView: CipherView,
        completion: @escaping @MainActor () async -> Void,
    ) async {
        repromptForMasterPasswordCipherView = cipherView
        if repromptForMasterPasswordAutoComplete {
            await completion()
        } else {
            repromptForMasterPasswordCompletion = completion
        }
    }
}
