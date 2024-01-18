import Foundation

extension Date {
    var epocUtcNowInMs: Int {
        Int(timeIntervalSince1970 * 1000)
    }
}
