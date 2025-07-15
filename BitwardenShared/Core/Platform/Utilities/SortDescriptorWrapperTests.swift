import XCTest

@testable import BitwardenShared

// MARK: - SortDescriptorWrapperTests

class SortDescriptorWrapperTests: BitwardenTestCase {
    // MARK: Tests

    /// Using a `SortDescriptorWrapper` sorts an array of object in ascending manner for non-optional string value.
    func test_sortDescriptor_sortsAscending() {
        let sortDescriptor = SortDescriptorWrapper<FooToSort>(\.sortValue, comparator: .localizedStandard)
        let values = [
            FooToSort(sortValue: "one value"),
            FooToSort(sortValue: "2nd value"),
            FooToSort(sortValue: "old value"),
            FooToSort(sortValue: "1234567"),
            FooToSort(sortValue: "zzzzzzzz"),
            FooToSort(sortValue: "aaa"),
            FooToSort(sortValue: "bbbb"),
        ]
        XCTAssertEqual(values.sorted(using: sortDescriptor).map(\.sortValue), [
            "2nd value",
            "1234567",
            "aaa",
            "bbbb",
            "old value",
            "one value",
            "zzzzzzzz",
        ])
    }

    /// Using a `SortDescriptorWrapper` sort an array of objects in descending manner for optional string value.
    func test_sortDescriptor_sortsDescending() {
        let sortDescriptor = SortDescriptorWrapper<FooToSort>(
            \.optionalSortValue,
            comparator: .localizedStandard,
            order: .reverse
        )
        let values = [
            FooToSort(sortValue: "", optionalSortValue: "one value"),
            FooToSort(sortValue: "", optionalSortValue: "2nd value"),
            FooToSort(sortValue: "", optionalSortValue: "old value"),
            FooToSort(sortValue: "", optionalSortValue: "1234567"),
            FooToSort(sortValue: "", optionalSortValue: "zzzzzzzz"),
            FooToSort(sortValue: "", optionalSortValue: "aaa"),
            FooToSort(sortValue: "", optionalSortValue: "bbbb"),
        ]
        XCTAssertEqual(values.sorted(using: sortDescriptor).map(\.optionalSortValue), [
            "zzzzzzzz",
            "one value",
            "old value",
            "bbbb",
            "aaa",
            "1234567",
            "2nd value",
        ])
    }
}

/// A stub object to sort.
struct FooToSort {
    /// The value to use for sorting.
    let sortValue: String
    /// The value to use for sorting but as optional type.
    let optionalSortValue: String?

    init(sortValue: String, optionalSortValue: String? = nil) {
        self.sortValue = sortValue
        self.optionalSortValue = optionalSortValue
    }
}
