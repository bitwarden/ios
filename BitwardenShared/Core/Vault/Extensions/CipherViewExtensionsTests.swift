import BitwardenSdk
import BitwardenSharedMocks
import Foundation
import Testing

@testable import BitwardenShared

struct CipherViewExtensionsTests {
    // MARK: init(username:password:uri:name:creationDate:)

    /// `init(username:password:uri:name:creationDate:)` sets login fields and uses the provided name.
    @Test
    func init_login_withName() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let cipher = CipherView(
            username: "user@example.com",
            password: "hunter2",
            uri: "https://example.com",
            name: "Example",
            creationDate: date,
        )

        #expect(cipher.name == "Example")
        #expect(cipher.type == .login)
        #expect(cipher.login?.username == "user@example.com")
        #expect(cipher.login?.password == "hunter2")
        #expect(cipher.login?.uris?.first?.uri == "https://example.com")
        #expect(cipher.creationDate == date)
        #expect(cipher.revisionDate == date)
        #expect(!cipher.favorite)
        #expect(cipher.reprompt == .none)
        #expect(cipher.id == nil)
    }

    /// `init(username:password:uri:name:creationDate:)` derives the cipher name from the explicit name,
    /// URI host, or raw URI.
    @Test(arguments: [
        ("https://github.com/login", nil as String?, "github.com"),
        ("com.example.app", nil as String?, "com.example.app"),
        ("https://github.com", "Work GitHub" as String?, "Work GitHub"),
    ])
    func init_login_nameDerivation(uri: String, name: String?, expectedName: String) {
        let cipher = CipherView(username: "user", password: "pass", uri: uri, name: name)
        #expect(cipher.name == expectedName)
    }

    // MARK: canBeArchived

    /// `canBeArchived` returns the expected value for each combination of archived and deleted dates.
    @Test(arguments: [
        (nil as Date?, nil as Date?, true),
        (Date.distantPast, nil as Date?, false),
        (nil as Date?, Date.distantPast, false),
        (Date.distantPast, Date.distantPast, false),
    ])
    func canBeArchived(archivedDate: Date?, deletedDate: Date?, expected: Bool) {
        #expect(
            CipherView.fixture(archivedDate: archivedDate, deletedDate: deletedDate).canBeArchived == expected,
        )
    }

    // MARK: canBeUnarchived

    /// `canBeUnarchived` returns the expected value for each combination of archived and deleted dates.
    @Test(arguments: [
        (Date.distantPast, nil as Date?, true),
        (nil as Date?, nil as Date?, false),
        (nil as Date?, Date.distantPast, false),
        (Date.distantPast, Date.distantPast, false),
    ])
    func canBeUnarchived(archivedDate: Date?, deletedDate: Date?, expected: Bool) {
        #expect(
            CipherView.fixture(archivedDate: archivedDate, deletedDate: deletedDate).canBeUnarchived == expected,
        )
    }

    // MARK: isHidden

    /// `isHidden` returns the expected value for each combination of archived and deleted dates.
    @Test(arguments: [
        (Date.distantPast, nil as Date?, true),
        (nil as Date?, Date.distantPast, true),
        (Date.distantPast, Date.distantPast, true),
        (nil as Date?, nil as Date?, false),
    ])
    func isHidden(archivedDate: Date?, deletedDate: Date?, expected: Bool) {
        #expect(
            CipherView.fixture(archivedDate: archivedDate, deletedDate: deletedDate).isHidden == expected,
        )
    }
}
