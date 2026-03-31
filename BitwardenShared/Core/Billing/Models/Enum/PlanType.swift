/// An enum representing the type of subscription plan.
///
public enum PlanType: Int, Codable, Equatable, Sendable {
    /// Free plan.
    case free = 0

    /// Families plan (2019 version).
    case familiesAnnually2019 = 1

    /// Teams monthly plan (2019 version).
    case teamsMonthly2019 = 2

    /// Teams annual plan (2019 version).
    case teamsAnnually2019 = 3

    /// Enterprise monthly plan (2019 version).
    case enterpriseMonthly2019 = 4

    /// Enterprise annual plan (2019 version).
    case enterpriseAnnually2019 = 5

    /// Custom plan.
    case custom = 6

    /// Families plan (2025 version).
    case familiesAnnually2025 = 7

    /// Teams monthly plan (2020 version).
    case teamsMonthly2020 = 8

    /// Teams annual plan (2020 version).
    case teamsAnnually2020 = 9

    /// Enterprise monthly plan (2020 version).
    case enterpriseMonthly2020 = 10

    /// Enterprise annual plan (2020 version).
    case enterpriseAnnually2020 = 11

    /// Teams monthly plan (2023 version).
    case teamsMonthly2023 = 12

    /// Teams annual plan (2023 version).
    case teamsAnnually2023 = 13

    /// Enterprise monthly plan (2023 version).
    case enterpriseMonthly2023 = 14

    /// Enterprise annual plan (2023 version).
    case enterpriseAnnually2023 = 15

    /// Teams starter plan (2023 version).
    case teamsStarter2023 = 16

    /// Teams monthly plan (current).
    case teamsMonthly = 17

    /// Teams annual plan (current).
    case teamsAnnually = 18

    /// Enterprise monthly plan (current).
    case enterpriseMonthly = 19

    /// Enterprise annual plan (current).
    case enterpriseAnnually = 20

    /// Teams starter plan (current).
    case teamsStarter = 21

    /// Families annual plan (current).
    case familiesAnnually = 22
}
