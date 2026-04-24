import BitwardenKit
import Foundation
import Testing

struct TOTPCodeModelTests {
    // MARK: Tests

    /// `displayCode` groups digits correctly.
    @Test
    func displayCode_spaces() {
        #expect(model(for: "12345").displayCode == "123 45")
        #expect(model(for: "123456").displayCode == "123 456")
        #expect(model(for: "1234567").displayCode == "123 456 7")
        #expect(model(for: "12345678").displayCode == "123 456 78")
        #expect(model(for: "123456789").displayCode == "123 456 789")
        #expect(model(for: "1234567890").displayCode == "123 456 789 0")
    }

    // MARK: Private Methods

    private func model(for code: String) -> TOTPCodeModel {
        TOTPCodeModel(code: code, codeGenerationDate: Date(), period: 30)
    }
}
