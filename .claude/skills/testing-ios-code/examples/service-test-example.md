# Service Test Example

Based on: `BitwardenShared/Core/Platform/Services/` service test patterns

```swift
import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DefaultFeatureServiceTests

class DefaultFeatureServiceTests: BitwardenTestCase {
    // MARK: Properties

    var apiService: MockAPIService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DefaultFeatureService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        apiService = MockAPIService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = DefaultFeatureService(
            apiService: apiService,
            errorReporter: errorReporter,
            stateService: stateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        apiService = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `fetchItems()` returns items from the API on success.
    func test_fetchItems_success_returnsItems() async throws {
        apiService.fetchItemsResult = .success([.fixture()])

        let result = try await subject.fetchItems()

        XCTAssertEqual(result.count, 1)
    }

    /// `fetchItems()` throws when the API returns an error.
    func test_fetchItems_apiError_throws() async {
        apiService.fetchItemsResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.fetchItems()
        }
    }

    /// `fetchItems()` logs the error to the error reporter.
    func test_fetchItems_apiError_logsError() async {
        apiService.fetchItemsResult = .failure(BitwardenTestError.example)

        _ = try? await subject.fetchItems()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }
}
```

## Key Patterns

- Service tests subclass `BitwardenTestCase` like other tests
- Dependencies injected **directly** (not via `ServiceContainer.withMocks`) — services don't use `Has*` protocols internally
- No `@MainActor` needed unless the service explicitly dispatches to main
- Test success, error throwing, AND side effects (error reporting) separately
- `BitwardenTestError.example` — standard test error fixture
- `assertAsyncThrows(error:)` — helper for verifying thrown async errors
