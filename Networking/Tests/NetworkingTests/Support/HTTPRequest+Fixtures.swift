import Foundation

@testable import Networking

extension HTTPRequest {
    static let `default` = HTTPRequest(url: URL(string: "https://www.example.com")!)
}
