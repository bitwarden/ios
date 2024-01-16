import Foundation

class CipherServiceMock: CipherServiceProtocol {
    func fetchCiphers(_: String?) -> [Cipher] {
        ciphers
    }

    func deleteAll(_: String?, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func getCipher(_ id: String) -> Cipher? {
        CipherMock.ciphers.first { ci in
            ci.id == id
        }
    }

    func saveCiphers(_: [Cipher], completionHandler _: @escaping () -> Void) {}

    private var ciphers = [Cipher]()

    init() {
        ciphers = CipherMock.ciphers
    }
}
