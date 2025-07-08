import Foundation

// MARK: - SortDescriptorWrapper<T>

/// A wrapper of `SortDescriptor<T>` that uses the native descriptor if available
/// and fallbacks to `BackportSortDescriptor` otherwise.
/// This will no longer be necessary if the minimum iOS version is bumped to iOS 17.
struct SortDescriptorWrapper<T> {
    /// Comparator to use to sort.
    private let _compare: (T, T) -> ComparisonResult

    /// Initializes the sort descriptor.
    /// - Parameters:
    ///   - keyPath: The key path to use to sort.
    ///   - comparator: The comparator to use to sort the string.
    ///   - order: The sort order to use.
    init(
        _ keyPath: KeyPath<T, String>,
        comparator: String.StandardComparator,
        order: SortOrder = .forward
    ) {
        if #available(iOS 17, *) {
            // Use native SortDescriptor on iOS 17+
            let native = SortDescriptor(keyPath, comparator: comparator, order: order)
            _compare = { lhs, rhs in native.compare(lhs, rhs) }
        } else if #available(iOS 16, *) {
            let comparison = { (lhs: String, rhs: String) in
                comparator.compare(lhs, rhs)
            }
            // iOS 16 fallback using BackportSortDescriptor
            let backport = BackportSortDescriptor<T>(comparator: { lhs, rhs in
                let result = comparison(lhs[keyPath: keyPath], rhs[keyPath: keyPath])
                return order == .forward ? result : result.reversed()
            })
            _compare = backport.compare
        } else {
            // iOS 15 fallback using `localizedStandardCompare`.
            let backport = BackportSortDescriptor<T>(comparator: { lhs, rhs in
                let lhsStr = lhs[keyPath: keyPath]
                let rhsStr = rhs[keyPath: keyPath]
                let result = lhsStr.localizedStandardCompare(rhsStr)
                return order == .forward ? result : result.reversed()
            })
            _compare = backport.compare
        }
    }

    /// Initializes the sort descriptor.
    /// - Parameters:
    ///   - keyPath: The key path to use to sort.
    ///   - comparator: The comparator to use to sort the string.
    ///   - order: The sort order to use.
    init(
        _ keyPath: KeyPath<T, String?>,
        comparator: String.StandardComparator,
        order: SortOrder = .forward
    ) {
        if #available(iOS 17, *) {
            let native = SortDescriptor<T>(keyPath, comparator: comparator, order: order)
            _compare = { lhs, rhs in native.compare(lhs, rhs) }
        } else if #available(iOS 16, *) {
            let comparison: (String?, String?) -> ComparisonResult = { lhs, rhs in
                switch (lhs, rhs) {
                case let (lhsValue?, rhsValue?):
                    return comparator.compare(lhsValue, rhsValue)
                case (nil, nil):
                    return .orderedSame
                case (nil, _):
                    return .orderedAscending
                case (_, nil):
                    return .orderedDescending
                }
            }
            let backport = BackportSortDescriptor<T>(comparator: { lhs, rhs in
                let result = comparison(lhs[keyPath: keyPath], rhs[keyPath: keyPath])
                return order == .forward ? result : result.reversed()
            })
            _compare = backport.compare
        } else {
            // iOS 15 fallback using localizedStandardCompare
            let backport = BackportSortDescriptor<T>(comparator: { lhs, rhs in
                let lhsStr = lhs[keyPath: keyPath]
                let rhsStr = rhs[keyPath: keyPath]

                let result: ComparisonResult
                switch (lhsStr, rhsStr) {
                case let (lhsValue?, rhsValue?):
                    result = lhsValue.localizedStandardCompare(rhsValue)
                case (nil, nil):
                    result = .orderedSame
                case (nil, _):
                    result = .orderedAscending
                case (_, nil):
                    result = .orderedDescending
                }

                return order == .forward ? result : result.reversed()
            })
            _compare = backport.compare
        }
    }

    /// Initializes the sort descriptor.
    /// - Parameters:
    ///   - keyPath: The key path to use to sort.
    ///   - ascending: Whether the order should be ascending.
    init<Value: Comparable>(_ keyPath: KeyPath<T, Value>, ascending: Bool = true) {
        if #available(iOS 17, *) {
            let native = SortDescriptor(keyPath, order: ascending ? .forward : .reverse)
            _compare = { lhs, rhs in native.compare(lhs, rhs) }
        } else {
            let backport = BackportSortDescriptor<T>(key: keyPath, ascending: ascending)
            _compare = backport.compare
        }
    }

    /// Compares two values.
    func compare(_ lhs: T, _ rhs: T) -> ComparisonResult {
        _compare(lhs, rhs)
    }
}

// MARK: - BackportSortDescriptor<T>

/// Backport version of `SortDescriptor<T>` so it can be used on older than iOS 17 devices.
struct BackportSortDescriptor<T> {
    /// Comparator to use to sort.
    private let comparator: (T, T) -> ComparisonResult

    /// Initializes the sort descriptor.
    /// - Parameter comparator: The comparator closure to use to sort.
    init(comparator: @escaping (T, T) -> ComparisonResult) {
        self.comparator = comparator
    }

    /// Initializes the sort descriptor.
    /// - Parameters:
    ///   - key: The key path to use to sort.
    ///   - ascending: Whether the order should be ascending.
    init<Value: Comparable>(key: KeyPath<T, Value>, ascending: Bool = true) {
        comparator = { lhs, rhs in
            let lhsValue = lhs[keyPath: key]
            let rhsValue = rhs[keyPath: key]
            if lhsValue == rhsValue {
                return .orderedSame
            }
            return ascending
                ? (lhsValue < rhsValue ? .orderedAscending : .orderedDescending)
                : (lhsValue > rhsValue ? .orderedAscending : .orderedDescending)
        }
    }

    /// Compares two values.
    func compare(_ lhs: T, _ rhs: T) -> ComparisonResult {
        comparator(lhs, rhs)
    }
}

// MARK: - ComparisonResult

extension ComparisonResult {
    /// Inverts the order of a `ComparisonResult`.
    func reversed() -> ComparisonResult {
        switch self {
        case .orderedAscending:
            return .orderedDescending
        case .orderedDescending:
            return .orderedAscending
        case .orderedSame:
            return .orderedSame
        }
    }
}

// MARK: - Array extension

extension Array {
    /// Sorts using descriptors.
    /// - Parameter descriptor: The descriptor to use to sort the array.
    /// - Returns: The sorted array.
    func sorted(using descriptor: SortDescriptorWrapper<Element>) -> [Element] {
        sorted(using: [descriptor])
    }

    /// Sorts using descriptors.
    /// - Parameter descriptors: The descriptors to use to sort the array.
    /// - Returns: The sorted array.
    func sorted(using descriptors: [SortDescriptorWrapper<Element>]) -> [Element] {
        sorted { lhs, rhs in
            for descriptor in descriptors {
                let result = descriptor.compare(lhs, rhs)
                if result != .orderedSame {
                    return result == .orderedAscending
                }
            }
            return false
        }
    }
}
