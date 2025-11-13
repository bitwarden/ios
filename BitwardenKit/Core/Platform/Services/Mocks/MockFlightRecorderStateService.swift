import BitwardenKit
import TestHelpers

public class MockFlightRecorderStateService: FlightRecorderStateService {
    public var activeAccountIdResult = Result<String, Error>.failure(BitwardenTestError.example)
    public var flightRecorderData: FlightRecorderData?

    public init() {}

    public func getActiveAccountId() async throws -> String {
        try activeAccountIdResult.get()
    }

    public func getFlightRecorderData() async -> FlightRecorderData? {
        flightRecorderData
    }

    public func setFlightRecorderData(_ data: FlightRecorderData?) async {
        flightRecorderData = data
    }
}
