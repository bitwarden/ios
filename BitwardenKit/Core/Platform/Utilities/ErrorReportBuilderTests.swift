import BitwardenKit
import BitwardenKitMocks
import InlineSnapshotTesting
import TestHelpers
import XCTest

class ErrorReportBuilderTests: BitwardenTestCase {
    // MARK: Properties

    var appInfoService: MockAppInfoService!
    var activeAccountStateProvider: MockActiveAccountStateProvider!
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

        activeAccountStateProvider = MockActiveAccountStateProvider()
        appInfoService = MockAppInfoService()

        subject = DefaultErrorReportBuilder(
            activeAccountStateProvider: activeAccountStateProvider,
            appInfoService: appInfoService,
        )
    }

    override func tearDown() {
        super.tearDown()

        activeAccountStateProvider = nil
        appInfoService = nil
        subject = nil
    }

    // MARK: Tests

    /// `buildShareErrorLog(for:callStack:)` builds an error report to share for a `DecodingError`.
    func test_buildShareErrorLog_decodingError() async {
        enum TestKeys: CodingKey {
            case ciphers
        }

        activeAccountStateProvider.getActiveAccountIdReturnValue = "1"

        let errorReport = await subject.buildShareErrorLog(
            for: DecodingError.keyNotFound(
                TestKeys.ciphers,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "No value associated with key " +
                        "CodingKeys(stringValue: \"ciphers\", intValue: nil).",
                ),
            ),
            callStack: exampleCallStack,
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
            BitwardenKitTests:           0x0000000000000000
            AuthenticatorBridgeKitMocks: 0x0000000000000000
            BitwardenKit:                0x0000000000000000
            BitwardenKitMocks:           0x0000000000000000
            BitwardenResources:          0x0000000000000000
            AuthenticatorBridgeKit:      0x0000000000000000

            User ID: 1
            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            """#
        }
        // swiftlint:enable line_length
    }

    /// `buildShareErrorLog(for:callStack:)` builds an error report to share and handles there being
    /// no active account.
    func test_buildShareErrorLog_noActiveUser() async {
        activeAccountStateProvider.getActiveAccountIdClosure = { throw BitwardenTestError.example }
        let errorReport = await subject.buildShareErrorLog(
            for: BitwardenTestError.example,
            callStack: exampleCallStack,
        )
        assertInlineSnapshot(of: errorReport.replacingHexAddresses(), as: .lines) {
            """
            TestHelpers.BitwardenTestError.example
            An example error used to test throwing capabilities.

            Stack trace:
            0   BitwardenShared    0x00000000 AnyCoordinator.showErrorAlert(error:)
            1   BitwardenShared    0x00000000 VaultListProcessor.refreshVault()
            2   BitwardenShared    0x00000000 VaultListProcessor.perform(_:)
            3   BitwardenShared    0x00000000 StateProcessor<A, B, C>.perform(_:)

            Binary images:
            BitwardenKitTests:           0x0000000000000000
            AuthenticatorBridgeKitMocks: 0x0000000000000000
            BitwardenKit:                0x0000000000000000
            BitwardenKitMocks:           0x0000000000000000
            BitwardenResources:          0x0000000000000000
            AuthenticatorBridgeKit:      0x0000000000000000

            User ID: n/a
            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            """
        }
    }

    /// `buildShareErrorLog(for:callStack:)` builds an error report to share for a `StateServiceError`.
    func test_buildShareErrorLog_stateServiceError() async {
        activeAccountStateProvider.getActiveAccountIdReturnValue = "1"
        let errorReport = await subject.buildShareErrorLog(
            for: BitwardenTestError.example,
            callStack: exampleCallStack,
        )
        assertInlineSnapshot(of: errorReport.replacingHexAddresses(), as: .lines) {
            """
            TestHelpers.BitwardenTestError.example
            An example error used to test throwing capabilities.

            Stack trace:
            0   BitwardenShared    0x00000000 AnyCoordinator.showErrorAlert(error:)
            1   BitwardenShared    0x00000000 VaultListProcessor.refreshVault()
            2   BitwardenShared    0x00000000 VaultListProcessor.perform(_:)
            3   BitwardenShared    0x00000000 StateProcessor<A, B, C>.perform(_:)

            Binary images:
            BitwardenKitTests:           0x0000000000000000
            AuthenticatorBridgeKitMocks: 0x0000000000000000
            BitwardenKit:                0x0000000000000000
            BitwardenKitMocks:           0x0000000000000000
            BitwardenResources:          0x0000000000000000
            AuthenticatorBridgeKit:      0x0000000000000000

            User ID: 1
            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
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
