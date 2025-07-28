import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class ErrorReportBuilderTests: BitwardenTestCase {
    // MARK: Properties

    var appInfoService: MockAppInfoService!
    var stateService: MockStateService!
    var subject: ErrorReportBuilder!

    let exampleCallStack: String = """
    0   BitwardenShared    0x00000000 AnyCoordinator.showErrorAlert(error:)
    1   BitwardenShared    0x00000000 VaultListProcessor.refreshVault()
    2   BitwardenShared    0x00000000 VaultListProcessor.perform(_:)
    3   BitwardenShared    0x00000000 StateProcessor<A, B, C>.perform(_:)
    """

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appInfoService = MockAppInfoService()
        stateService = MockStateService()

        subject = DefaultErrorReportBuilder(appInfoService: appInfoService, stateService: stateService)
    }

    override func tearDown() {
        super.tearDown()

        appInfoService = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `buildShareErrorLog(for:callStack:)` builds an error report to share for a `DecodingError`.
    func test_buildShareErrorLog_decodingError() async {
        enum TestKeys: CodingKey {
            case ciphers
        }

        stateService.activeAccount = .fixture()

        let errorReport = await subject.buildShareErrorLog(
            for: DecodingError.keyNotFound(
                TestKeys.ciphers,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "No value associated with key " +
                        "CodingKeys(stringValue: \"ciphers\", intValue: nil)."
                )
            ),
            callStack: exampleCallStack
        )
        // swiftlint:disable line_length
        assertInlineSnapshot(of: errorReport.replacingHexAddresses(), as: .lines) {
            #"""
            Swift.DecodingError.keyNotFound(TestKeys(stringValue: "ciphers", intValue: nil), Swift.DecodingError.Context(codingPath: [], debugDescription: "No value associated with key CodingKeys(stringValue: \"ciphers\", intValue: nil).", underlyingError: nil))
            The data couldn’t be read because it is missing.

            Stack trace:
            0   BitwardenShared    0x00000000 AnyCoordinator.showErrorAlert(error:)
            1   BitwardenShared    0x00000000 VaultListProcessor.refreshVault()
            2   BitwardenShared    0x00000000 VaultListProcessor.perform(_:)
            3   BitwardenShared    0x00000000 StateProcessor<A, B, C>.perform(_:)

            Binary images:
            Bitwarden:               0x0000000000000000
            Bitwarden.debug.dylib:   0x0000000000000000
            BitwardenShared:         0x0000000000000000
            BitwardenKit:            0x0000000000000000
            BitwardenResources:      0x0000000000000000
            BitwardenSharedTests:    0x0000000000000000
            BitwardenKitMocks:       0x0000000000000000

            User ID: 1
            Version: 1.0 (1)
            📱 iPhone14,2 🍏 iOS 16.4 📦 Production
            """#
        }
        // swiftlint:enable line_length
    }

    /// `buildShareErrorLog(for:callStack:)` builds an error report to share and handles there being
    /// no active account.
    func test_buildShareErrorLog_noActiveUser() async {
        let errorReport = await subject.buildShareErrorLog(
            for: StateServiceError.noActiveAccount,
            callStack: exampleCallStack
        )
        assertInlineSnapshot(of: errorReport.replacingHexAddresses(), as: .lines) {
            """
            BitwardenShared.StateServiceError.noActiveAccount
            No account found. Please log in again if you continue to see this error.

            Stack trace:
            0   BitwardenShared    0x00000000 AnyCoordinator.showErrorAlert(error:)
            1   BitwardenShared    0x00000000 VaultListProcessor.refreshVault()
            2   BitwardenShared    0x00000000 VaultListProcessor.perform(_:)
            3   BitwardenShared    0x00000000 StateProcessor<A, B, C>.perform(_:)

            Binary images:
            Bitwarden:               0x0000000000000000
            Bitwarden.debug.dylib:   0x0000000000000000
            BitwardenShared:         0x0000000000000000
            BitwardenKit:            0x0000000000000000
            BitwardenResources:      0x0000000000000000
            BitwardenSharedTests:    0x0000000000000000
            BitwardenKitMocks:       0x0000000000000000

            User ID: n/a
            Version: 1.0 (1)
            📱 iPhone14,2 🍏 iOS 16.4 📦 Production
            """
        }
    }

    /// `buildShareErrorLog(for:callStack:)` builds an error report to share for a `StateServiceError`.
    func test_buildShareErrorLog_stateServiceError() async {
        stateService.activeAccount = .fixture()
        let errorReport = await subject.buildShareErrorLog(
            for: StateServiceError.noActiveAccount,
            callStack: exampleCallStack
        )
        assertInlineSnapshot(of: errorReport.replacingHexAddresses(), as: .lines) {
            """
            BitwardenShared.StateServiceError.noActiveAccount
            No account found. Please log in again if you continue to see this error.

            Stack trace:
            0   BitwardenShared    0x00000000 AnyCoordinator.showErrorAlert(error:)
            1   BitwardenShared    0x00000000 VaultListProcessor.refreshVault()
            2   BitwardenShared    0x00000000 VaultListProcessor.perform(_:)
            3   BitwardenShared    0x00000000 StateProcessor<A, B, C>.perform(_:)

            Binary images:
            Bitwarden:               0x0000000000000000
            Bitwarden.debug.dylib:   0x0000000000000000
            BitwardenShared:         0x0000000000000000
            BitwardenKit:            0x0000000000000000
            BitwardenResources:      0x0000000000000000
            BitwardenSharedTests:    0x0000000000000000
            BitwardenKitMocks:       0x0000000000000000

            User ID: 1
            Version: 1.0 (1)
            📱 iPhone14,2 🍏 iOS 16.4 📦 Production
            """
        }
    }
}

private extension String {
    /// Replaces any hex addresses within a string with all zeros.
    func replacingHexAddresses() -> String {
        let pattern = "0x[0-9a-fA-F]{12,16}" // Matches 12 to 16 hex digits after '0x'
        let replacement = "0x0000000000000000"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(startIndex ..< endIndex, in: self)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replacement)
        } catch {
            return self
        }
    }
}
