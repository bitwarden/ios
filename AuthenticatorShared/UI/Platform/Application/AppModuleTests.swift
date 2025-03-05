import SwiftUI
import XCTest

@testable import AuthenticatorShared

class AppModuleTests: BitwardenTestCase {
    // MARK: Properties

    var rootViewController: RootViewController!
    var subject: DefaultAppModule!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        rootViewController = RootViewController()
        subject = DefaultAppModule(services: .withMocks())
    }

    override func tearDown() {
        super.tearDown()

        rootViewController = nil
        subject = nil
    }
}
