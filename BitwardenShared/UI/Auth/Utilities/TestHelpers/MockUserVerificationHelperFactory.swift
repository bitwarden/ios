@testable import BitwardenShared

struct MockUserVerificationHelperFactory: UserVerificationHelperFactory {
    var createResult: UserVerificationHelper?

    func create() -> UserVerificationHelper {
        createResult ?? MockUserVerificationHelper()
    }
}
