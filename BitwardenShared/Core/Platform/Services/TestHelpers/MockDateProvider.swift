import Foundation

@testable import BitwardenShared

final class MockDateProvider: DateProvider, Sendable {
    let now = Date(timeIntervalSinceReferenceDate: 0)
}
