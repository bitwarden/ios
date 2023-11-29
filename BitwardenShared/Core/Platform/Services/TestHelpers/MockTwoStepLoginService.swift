import Foundation

@testable import BitwardenShared

class MockTwoStepLoginService: TwoStepLoginService {
    func twoStepLoginUrl() -> URL {
        URL.example
    }
}
