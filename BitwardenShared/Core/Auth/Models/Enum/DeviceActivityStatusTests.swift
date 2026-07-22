import BitwardenKitMocks
import BitwardenResources
import Foundation
import Testing

@testable import BitwardenShared

// MARK: - DeviceActivityStatusTests

struct DeviceActivityStatusTests {
    // MARK: Properties

    var timeProvider: MockTimeProvider

    // MARK: Initialization

    init() {
        timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1_718_000_000)))
    }

    // MARK: Tests

    /// `init(from:timeProvider:)` returns `.unknown` when the date is nil.
    @Test
    func init_nilDate() {
        #expect(DeviceActivityStatus(from: nil, timeProvider: timeProvider) == .unknown)
    }

    /// `init(from:timeProvider:)` returns `.unknown` when the date is in the future.
    @Test
    func init_futureDate() {
        let futureDate = timeProvider.presentTime.addingTimeInterval(3600)
        #expect(DeviceActivityStatus(from: futureDate, timeProvider: timeProvider) == .unknown)
    }

    /// `init(from:timeProvider:)` returns `.today` when the date is today (0 days ago).
    @Test
    func init_today() {
        let date = timeProvider.presentTime.addingTimeInterval(-3600)
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .today)
    }

    /// `init(from:timeProvider:)` returns `.pastSevenDays` at the 1-day boundary.
    @Test
    func init_pastSevenDays_lowerBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -1, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .pastSevenDays)
    }

    /// `init(from:timeProvider:)` returns `.pastSevenDays` at the 6-day boundary.
    @Test
    func init_pastSevenDays_upperBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -6, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .pastSevenDays)
    }

    /// `init(from:timeProvider:)` returns `.pastFourteenDays` at the 7-day boundary.
    @Test
    func init_pastFourteenDays_lowerBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -7, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .pastFourteenDays)
    }

    /// `init(from:timeProvider:)` returns `.pastFourteenDays` at the 13-day boundary.
    @Test
    func init_pastFourteenDays_upperBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -13, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .pastFourteenDays)
    }

    /// `init(from:timeProvider:)` returns `.pastThirtyDays` at the 14-day boundary.
    @Test
    func init_pastThirtyDays_lowerBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -14, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .pastThirtyDays)
    }

    /// `init(from:timeProvider:)` returns `.pastThirtyDays` at the 29-day boundary.
    @Test
    func init_pastThirtyDays_upperBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -29, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .pastThirtyDays)
    }

    /// `init(from:timeProvider:)` returns `.overThirtyDaysAgo` at the 30-day boundary.
    @Test
    func init_overThirtyDaysAgo_lowerBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -30, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .overThirtyDaysAgo)
    }

    /// `localizedString` returns the correct value for each status.
    @Test
    func localizedString() {
        #expect(DeviceActivityStatus.today.localizedString == Localizations.today)
        #expect(DeviceActivityStatus.pastSevenDays.localizedString == Localizations.pastSevenDays)
        #expect(DeviceActivityStatus.pastFourteenDays.localizedString == Localizations.pastFourteenDays)
        #expect(DeviceActivityStatus.pastThirtyDays.localizedString == Localizations.pastThirtyDays)
        #expect(DeviceActivityStatus.overThirtyDaysAgo.localizedString == Localizations.overThirtyDaysAgo)
        #expect(DeviceActivityStatus.unknown.localizedString == Localizations.unknown)
    }
}
