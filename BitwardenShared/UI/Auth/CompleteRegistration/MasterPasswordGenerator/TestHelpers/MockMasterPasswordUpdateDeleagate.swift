import Foundation

@testable import BitwardenShared

class MockMasterPasswordUpdateDelegate: MasterPasswordUpdateDelegate {
    var updatedPassword: String = ""
    var updateMasterPasswordCalled = false

    func didUpdateMasterPassword(password: String) {
        updatedPassword = password
        updateMasterPasswordCalled = true
    }
}
