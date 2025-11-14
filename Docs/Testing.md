# Testing Guide

## Table of Contents

- [Testing Philosophy](#testing-philosophy)
- [Test File Naming and Location](#test-file-naming-and-location)
- [Decision Tree: What Tests to Write](#decision-tree-what-tests-to-write)
- [Testing Strategies](#testing-strategies)
- [Testing by Component Type](#testing-by-component-type)
  - [Testing Processors](#testing-processors)
  - [Testing Services](#testing-services)
  - [Testing Repositories](#testing-repositories)
  - [Testing Views](#testing-views)
  - [Testing Coordinators](#testing-coordinators)
- [Common Testing Patterns](#common-testing-patterns)
- [Mock Generation and Usage](#mock-generation-and-usage)
- [Running Tests](#running-tests)
  - [Test Plans](#test-plans)
  - [Running Tests from Command Line](#running-tests-from-command-line)
  - [Running Tests from Xcode](#running-tests-from-xcode)
  - [Simulator Configuration](#simulator-configuration)
  - [Recording New Snapshots](#recording-new-snapshots)
- [Test Maintenance](#test-maintenance)
  - [When to Update Tests](#when-to-update-tests)
  - [Test Smells to Avoid](#test-smells-to-avoid)
  - [Test Coverage Guidelines](#test-coverage-guidelines)
  - [Debugging Failing Tests](#debugging-failing-tests)
  - [Continuous Integration](#continuous-integration)
- [Quick Reference for AI Agents](#quick-reference-for-ai-agents)
  - [Decision Matrix: Test Type Selection](#decision-matrix-test-type-selection)
  - [Common Test Patterns Quick Reference](#common-test-patterns-quick-reference)
  - [Test Checklist for AI Agents](#test-checklist-for-ai-agents)
  - [Test Ordering Guidelines](#test-ordering-guidelines)

## Testing Philosophy

Every type containing logic **must** be tested. The test suite should:

1. Validate business logic and state management
2. Verify user interactions trigger correct behaviors
3. Catch visual regressions across display modes
4. Enable confident refactoring through comprehensive coverage

## Test File Naming and Location

### Naming Conventions

- **Unit tests**: `<TypeToTest>Tests.swift`
- **Snapshot tests**: `<TypeToTest>+SnapshotTests.swift`
- **View Inspector tests**: `<TypeToTest>+ViewInspectorTests.swift`

### File Location

Test files **must** be co-located with the implementation file in the same folder:

```
BitwardenShared/UI/Platform/Application/
├── AppProcessor.swift
├── AppProcessorTests.swift          # Unit tests
├── AppView.swift
├── AppView+SnapshotTests.swift      # Snapshot tests
└── AppView+ViewInspectorTests.swift # View inspector tests
```

This makes it easy to:
- Find tests for a specific type
- Open implementation and tests side-by-side
- Ensure tests evolve with the code

## Decision Tree: What Tests to Write

Use this decision tree to determine which tests to write for a new or modified component:

```
┌─────────────────────────────────────┐
│ What type of component is this?     │
└─────────────────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼────┐  ┌────▼───┐  ┌─────▼──┐
│ Model  │  │ Logic  │  │  View  │
└───┬────┘  └───┬────┘  └────┬───┘

┌──────────────────────────────────────┐
│ Model (Domain/Request/Response)      │
│ ✓ Unit tests for:                    │
│   - Codable conformance              │
│   - Custom init logic                │
│   - Computed properties              │
│   - Validation methods               │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ Logic Component                      │
│ (Processor/Service/Repository/Store) │
│ ✓ Unit tests for:                    │
│   - All public methods               │
│   - State mutations                  │
│   - Error handling                   │
│   - Async operations                 │
│   - Edge cases                       │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ View (SwiftUI)                       │
│ ✓ ViewInspector tests for:           │
│   - Button taps send actions         │
│   - Toggle changes send actions      │
│   - TextField bindings work          │
│   - Navigation triggers              │
│ ✓ Snapshot tests for:                │
│   - Light mode                       │
│   - Dark mode                        │
│   - Large dynamic type               │
│   - Loading/error/empty states       │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ Coordinator                          │
│ ✓ Unit tests for:                    │
│   - Route navigation                 │
│   - Child coordinator creation       │
│   - Event handling                   │
│   - Context passing                  │
└──────────────────────────────────────┘
```

## Testing Strategies

### 1. Unit Tests (XCTest / Swift Testing)

**Purpose**: Validate business logic, state management, and data transformations

**Tools**:
- [XCTest](https://developer.apple.com/documentation/xctest) (legacy, still widely used)
- [Swift Testing Framework](https://developer.apple.com/xcode/swift-testing/) (preferred for new tests)

**Use for**:
- Processors (state mutations, action handling, effects)
- Services (business logic, data transformations)
- Repositories (data synthesis, error handling)
- Data Stores (persistence operations)
- Models (codable, computed properties, validation)
- Coordinators (navigation logic)

### 2. ViewInspector Tests

**Purpose**: Verify user interactions send correct actions/effects through the Store

**Tool**: [ViewInspector](https://github.com/nalexn/ViewInspector)

**Use for**:
- Button taps trigger actions
- Toggle changes send state updates
- TextField bindings work correctly
- Sheet/alert presentations
- Navigation link triggers

### 3. Snapshot Tests

**Purpose**: Catch visual regressions across different display modes

**Tool**: [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing)

**Use for**:
- All user-facing views
- Different states (loading, error, empty, populated)
- Accessibility configurations

**Required Snapshots**:
- ✅ Light mode
- ✅ Dark mode
- ✅ Large dynamic type (accessibility)

**Important**: Snapshot tests **must** run on the specific simulator defined in:
- Device: [.test-simulator-device-name](../.test-simulator-device-name)
- iOS Version: [.test-simulator-ios-version](../.test-simulator-ios-version)

Otherwise, tests will fail due to rendering differences between iOS versions.

## Testing by Component Type

### Testing Processors

Processors manage state and handle actions/effects. Focus on:

#### What to Test
- ✅ Initial state is correct
- ✅ Actions update state correctly
- ✅ Effects perform async work and update state
- ✅ Navigation requests are sent to coordinator
- ✅ Error handling updates state appropriately

#### Example Test Structure

```swift
@testable import BitwardenShared
import XCTest

class ExampleProcessorTests: BitwardenTestCase {
    var subject: ExampleProcessor!
    var coordinator: MockCoordinator<ExampleRoute, Void>!
    var exampleRepository: MockExampleRepository!

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        exampleRepository = MockExampleRepository()

        subject = ExampleProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                exampleRepository: exampleRepository
            ),
            state: ExampleState()
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
        coordinator = nil
        exampleRepository = nil
    }

    // Test action handling
    func test_receive_toggleAction_updatesState() {
        subject.state.isToggleOn = false

        subject.receive(.toggleChanged(true))

        XCTAssertTrue(subject.state.isToggleOn)
    }

    // Test effect handling
    func test_perform_loadData_success_updatesState() async {
        exampleRepository.loadDataResult = .success("Test Data")

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.data, "Test Data")
        XCTAssertFalse(subject.state.isLoading)
    }

    // Test navigation
    func test_receive_nextAction_navigatesToNextScreen() {
        subject.receive(.next)

        XCTAssertEqual(coordinator.routes.last, .nextExample)
    }

    // Test error handling
    func test_perform_loadData_failure_showsError() async {
        exampleRepository.loadDataResult = .failure(BitwardenTestError.example)

        await subject.perform(.loadData)

        XCTAssertNotNil(subject.state.errorAlert)
    }
}
```

### Testing Services

Services have discrete responsibilities. Focus on:

#### What to Test
- ✅ All public method signatures
- ✅ Data transformations
- ✅ Error propagation
- ✅ Interaction with dependencies (use mocks)
- ✅ Edge cases and boundary conditions

#### Example Pattern

```swift
class ExampleServiceTests: BitwardenTestCase {
    var subject: DefaultExampleService!
    var dataStore: MockDataStore!
    var apiService: MockAPIService!

    override func setUp() {
        super.setUp()
        dataStore = MockDataStore()
        apiService = MockAPIService()
        subject = DefaultExampleService(
            dataStore: dataStore,
            apiService: apiService
        )
    }

    func test_fetchData_returnsMergedData() async throws {
        // Arrange
        dataStore.fetchResult = [/* local data */]
        apiService.fetchResult = .success(/* remote data */)

        // Act
        let result = try await subject.fetchData()

        // Assert
        XCTAssertEqual(result.count, expectedCount)
        XCTAssertTrue(dataStore.fetchCalled)
        XCTAssertTrue(apiService.fetchCalled)
    }
}
```

### Testing Repositories

Repositories synthesize data from multiple sources. Focus on:

#### What to Test
- ✅ Data synthesis from multiple services
- ✅ Async operation coordination
- ✅ Error handling from various sources
- ✅ Publisher streams emit correct values
- ✅ State synchronization

#### Example Pattern

```swift
class ExampleRepositoryTests: BitwardenTestCase {
    var subject: DefaultExampleRepository!
    var exampleService: MockExampleService!
    var otherService: MockOtherService!

    func test_loadData_combinesMultipleSources() async throws {
        exampleService.dataResult = .success(data1)
        otherService.dataResult = .success(data2)

        let result = try await subject.loadData()

        // Verify data was combined correctly
        XCTAssertEqual(result.combinedField, expectedValue)
    }
}
```

### Testing Views

Views render state and send actions. Focus on:

#### ViewInspector Tests: User Interactions

```swift
@testable import BitwardenShared
import ViewInspector
import XCTest

class ExampleViewTests: BitwardenTestCase {
    var processor: MockProcessor<ExampleState, ExampleAction, ExampleEffect>!
    var subject: ExampleView!

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: ExampleState())
        subject = ExampleView(store: Store(processor: processor))
    }

    // Test button tap
    func test_nextButton_tapped_sendsAction() throws {
        let button = try subject.inspect().find(button: "Next")
        try button.tap()

        XCTAssertEqual(processor.actions.last, .next)
    }

    // Test toggle
    func test_toggle_changed_sendsAction() throws {
        let toggle = try subject.inspect().find(ViewType.Toggle.self)
        try toggle.tap()

        XCTAssertEqual(processor.actions.last, .toggleChanged(true))
    }
}
```

#### Snapshot Tests: Visual Verification

```swift
@testable import BitwardenShared
import SnapshotTesting
import XCTest

class ExampleView_SnapshotTests: BitwardenTestCase {
    var subject: ExampleView!

    override func setUp() {
        super.setUp()
        subject = ExampleView(
            store: Store(
                processor: StateProcessor(
                    state: ExampleState(/* configure state */)
                )
            )
        )
    }

    // Test all required modes
    func test_snapshot_lightMode() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_darkMode() {
        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    func test_snapshot_largeDynamicType() {
        assertSnapshot(of: subject, as: .defaultPortraitAX5)
    }

    // Test different states
    func test_snapshot_loadingState() {
        subject.store.state.isLoading = true
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_errorState() {
        subject.store.state.errorMessage = "Something went wrong"
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
```

### Testing Coordinators

Coordinators handle navigation. Focus on:

#### What to Test
- ✅ Route navigation creates correct views/coordinators
- ✅ Child coordinators are created with correct dependencies
- ✅ Event handling triggers correct routes
- ✅ Context is passed correctly

#### Example Pattern

```swift
class ExampleCoordinatorTests: BitwardenTestCase {
    var subject: ExampleCoordinator!
    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!

    override func setUp() {
        super.setUp()
        module = MockAppModule()
        stackNavigator = MockStackNavigator()
        subject = ExampleCoordinator(
            module: module,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
    }

    func test_navigate_example_showsView() {
        subject.navigate(to: .example)

        XCTAssertTrue(stackNavigator.pushed)
        XCTAssertTrue(stackNavigator.pushedView is ExampleView)
    }

    func test_navigate_nextExample_createsChildCoordinator() {
        subject.navigate(to: .nextExample)

        XCTAssertTrue(module.makeNextExampleCoordinatorCalled)
    }
}
```

## Common Testing Patterns

### Pattern 1: Testing Async Operations

```swift
func test_asyncOperation_updatesState() async {
    // Setup mock result
    mockService.result = .success(expectedData)

    // Perform async effect
    await subject.perform(.loadData)

    // Assert state was updated
    XCTAssertEqual(subject.state.data, expectedData)
    XCTAssertFalse(subject.state.isLoading)
}
```

### Pattern 2: Testing Error Handling

```swift
func test_operation_failure_showsAlert() async {
    mockService.result = .failure(TestError.example)

    await subject.perform(.loadData)

    XCTAssertNotNil(subject.state.alert)
    XCTAssertEqual(subject.state.alert?.title, "Error")
}
```

### Pattern 3: Testing Publisher Streams

```swift
func test_publisher_emitsCorrectValues() async throws {
    var receivedValues: [String] = []

    let cancellable = subject.dataPublisher
        .sink { value in
            receivedValues.append(value)
        }

    // Trigger updates
    await subject.updateData("Value1")
    await subject.updateData("Value2")

    XCTAssertEqual(receivedValues, ["Value1", "Value2"])
    cancellable.cancel()
}
```

### Pattern 4: Testing State Equality

```swift
func test_state_equality() {
    let state1 = ExampleState(data: "test", isLoading: false)
    let state2 = ExampleState(data: "test", isLoading: false)
    let state3 = ExampleState(data: "other", isLoading: false)

    XCTAssertEqual(state1, state2)
    XCTAssertNotEqual(state1, state3)
}
```

## Mock Generation and Usage

### Generating Mocks with Sourcery

The codebase uses [Sourcery](https://github.com/krzysztofzablocki/Sourcery) to auto-generate mocks.

#### Mark a Protocol for Mocking

```swift
// sourcery: AutoMockable
protocol ExampleService {
    func fetchData() async throws -> [String]
    var dataPublisher: AnyPublisher<[String], Never> { get }
}
```

#### Generated Mock Location

Mocks are generated in:
- `BitwardenShared/Core/Platform/Models/Sourcery/AutoMockable.generated.swift`

#### Using Generated Mocks

```swift
class ExampleTests: BitwardenTestCase {
    var mockService: MockExampleService!

    override func setUp() {
        super.setUp()
        mockService = MockExampleService()
    }

    func test_example() async throws {
        // Setup mock behavior
        mockService.fetchDataResult = .success(["data1", "data2"])

        // Use in system under test
        let result = try await mockService.fetchData()

        // Verify
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(mockService.fetchDataCalled)
    }
}
```

### ServiceContainer with Mocks

Use `ServiceContainer.withMocks()` to inject dependencies:

```swift
let services = ServiceContainer.withMocks(
    exampleRepository: mockExampleRepository,
    exampleService: mockExampleService
)

let processor = ExampleProcessor(
    coordinator: coordinator.asAnyCoordinator(),
    services: services,
    state: ExampleState()
)
```

## Running Tests

### Test Plans

Test plans are organized in the `TestPlans` folder. Each project has multiple test plans to allow running specific subsets of tests:

#### Test Plan Structure

- `{ProjectName}-Default.xctestplan`: All tests (unit, snapshot, view inspector)
- `{ProjectName}-Unit.xctestplan`: Unit tests only (any simulator)
- `{ProjectName}-Snapshot.xctestplan`: Snapshot tests only (specific simulator required)
- `{ProjectName}-ViewInspector.xctestplan`: View inspector tests only

#### Available Projects

- `Bitwarden`: Password Manager app
- `Authenticator`: Authenticator app
- `BitwardenKit`: Shared framework

### Running Tests from Command Line

#### Run All Tests

```bash
xcodebuild test \
  -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -testPlan Bitwarden-Default \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

#### Run Unit Tests Only

```bash
xcodebuild test \
  -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -testPlan Bitwarden-Unit \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

#### Run Snapshot Tests Only

**Important**: Must use the specific simulator from configuration files:

```bash
# Read the required simulator configuration
DEVICE=$(cat .test-simulator-device-name)
IOS_VERSION=$(cat .test-simulator-ios-version)

xcodebuild test \
  -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -testPlan Bitwarden-Snapshot \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=$IOS_VERSION"
```

#### Run a Specific Test

```bash
xcodebuild test \
  -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -only-testing:BitwardenShared-Tests/ExampleProcessorTests/test_receive_action_updatesState
```

### Running Tests from Xcode

1. **Select Test Plan**: Product → Scheme → Edit Scheme → Test → Select Test Plan
2. **Run All Tests**: Cmd+U
3. **Run Specific Test**: Click the diamond icon next to the test method
4. **Run Test Class**: Click the diamond icon next to the class name

### Simulator Configuration

#### Unit Tests

Unit tests can run on **any simulator** thanks to the `SKIP_SIMULATOR_CHECK_FOR_TESTS` environment variable enabled in all Unit test plans.

#### Snapshot Tests

Snapshot tests **must** run on the specific simulator to avoid false failures:

- **Device**: Defined in [.test-simulator-device-name](../.test-simulator-device-name)
- **iOS Version**: Defined in [.test-simulator-ios-version](../.test-simulator-ios-version)

To verify you're using the correct simulator:

```bash
cat .test-simulator-device-name  # e.g., "iPhone 15 Pro"
cat .test-simulator-ios-version   # e.g., "17.0"
```

### Recording New Snapshots

When creating new snapshot tests or updating UI:

1. Run snapshot tests with recording enabled:
   ```bash
   # Set environment variable to record new snapshots
   RECORD_MODE=1 xcodebuild test -testPlan Bitwarden-Snapshot ...
   ```

2. Or in Xcode, edit the test scheme and add environment variable:
   - Key: `RECORD_MODE`
   - Value: `1`

3. Run the tests to record snapshots

4. Remove the environment variable and run tests again to verify

5. Commit the new snapshot images with your changes

## Test Maintenance

### When to Update Tests

#### After Changing Logic
- ✅ Update tests immediately after changing business logic
- ✅ Ensure all affected test cases pass
- ✅ Add new test cases for new branches/edge cases

#### After Changing UI
- ✅ Update ViewInspector tests if interactions changed
- ✅ Re-record snapshots if visual changes are intentional
- ✅ Verify snapshots in all modes (light, dark, accessibility)

#### After Refactoring
- ✅ Update test setup if dependencies changed
- ✅ Ensure tests still cover the same scenarios
- ✅ Remove obsolete tests for deleted code

### Test Smells to Avoid

#### ❌ Flaky Tests

**Symptoms**:
- Tests pass sometimes, fail other times
- Tests depend on timing or order
- Tests depend on external state

**Solutions**:
- Use async/await properly with proper waits
- Mock time-dependent operations
- Reset state in `setUp()` and `tearDown()`
- Avoid shared mutable state between tests

#### ❌ Testing Multiple Concerns

**Bad**: One test validates multiple unrelated things

```swift
// Bad: Testing too much in one test
func test_everything() async {
    await subject.perform(.loadData)
    XCTAssertFalse(subject.state.isLoading)
    XCTAssertNotNil(subject.state.data)

    subject.receive(.toggleChanged(true))
    XCTAssertTrue(subject.state.isToggleOn)

    subject.receive(.next)
    XCTAssertEqual(coordinator.routes.last, .next)
}
```

**Good**: Separate tests for separate concerns

```swift
// Good: One test, one concern
func test_perform_loadData_updatesState() async {
    await subject.perform(.loadData)
    XCTAssertEqual(subject.state.data, expectedData)
}

func test_receive_toggleChanged_updatesToggle() {
    subject.receive(.toggleChanged(true))
    XCTAssertTrue(subject.state.isToggleOn)
}

func test_receive_next_navigates() {
    subject.receive(.next)
    XCTAssertEqual(coordinator.routes.last, .next)
}
```

#### ❌ Not Using Mocks

**Bad**: Tests that depend on real services/network

```swift
// Bad: Using real repository
func test_loadData() async {
    let repository = DefaultExampleRepository(/* real dependencies */)
    // This makes real API calls!
}
```

**Good**: Tests that use mocks for isolation

```swift
// Good: Using mocked repository
func test_loadData() async {
    mockRepository.loadDataResult = .success(testData)
    await subject.perform(.loadData)
    XCTAssertEqual(subject.state.data, testData)
}
```

### Test Coverage Guidelines

#### Aim for High Coverage

- **Processors**: 100% coverage of actions, effects, state mutations
- **Services**: 90%+ coverage of public methods
- **Repositories**: 90%+ coverage of public methods
- **Coordinators**: 80%+ coverage of routes
- **Views**: All user interactions tested with ViewInspector
- **Models**: Test custom logic, computed properties, validation

#### What NOT to Test

- ❌ Third-party framework internals
- ❌ Apple SDK behaviors
- ❌ Simple getters/setters without logic
- ❌ Trivial computed properties that delegate to another property

### Debugging Failing Tests

#### Step 1: Isolate the Failure

```bash
# Run only the failing test
xcodebuild test -only-testing:Target/TestClass/testMethod
```

#### Step 2: Check Test Output

- Read the failure message carefully
- Check expected vs actual values
- Look for assertion failures

#### Step 3: Add Debugging

```swift
func test_example() async {
    print("State before: \(subject.state)")
    await subject.perform(.loadData)
    print("State after: \(subject.state)")
    print("Mock was called: \(mockService.fetchDataCalled)")

    XCTAssertEqual(subject.state.data, expectedData)
}
```

#### Step 4: Check Mock Setup

```swift
// Verify mock is configured correctly
func test_example() async {
    // Explicitly verify mock result is set
    XCTAssertNotNil(mockService.fetchDataResult)

    await subject.perform(.loadData)

    // Verify mock was called
    XCTAssertTrue(mockService.fetchDataCalled)
}
```

#### Step 5: Snapshot Test Failures

For snapshot test failures:

1. Check if you're using the correct simulator
2. Review the failure diff images in the test results
3. If visual changes are intentional, re-record the snapshot
4. If unintentional, fix the UI bug

### Continuous Integration

Tests run automatically on CI for:
- ✅ Pull requests to `main`
- ✅ Commits to `main`
- ✅ Release branches

CI runs all test plans:
- Unit tests (fast feedback)
- Snapshot tests (visual regression detection)
- View inspector tests (interaction validation)

Ensure all tests pass locally before pushing to prevent CI failures.

## Quick Reference for AI Agents

### Decision Matrix: Test Type Selection

| Component Type | Unit Tests | ViewInspector | Snapshots |
|---------------|------------|---------------|-----------|
| Processor     | ✅ Required | ❌ N/A        | ❌ N/A    |
| Service       | ✅ Required | ❌ N/A        | ❌ N/A    |
| Repository    | ✅ Required | ❌ N/A        | ❌ N/A    |
| Store         | ✅ Required | ❌ N/A        | ❌ N/A    |
| Coordinator   | ✅ Required | ❌ N/A        | ❌ N/A    |
| Model         | ✅ If logic | ❌ N/A        | ❌ N/A    |
| View          | ❌ N/A     | ✅ Required   | ✅ Required |

### Common Test Patterns Quick Reference

```swift
// 1. Processor Test Template
func test_action_behavior() {
    subject.receive(.action)
    XCTAssertEqual(subject.state.property, expected)
}

// 2. Async Effect Test Template
func test_effect_behavior() async {
    mockService.result = .success(data)
    await subject.perform(.effect)
    XCTAssertEqual(subject.state.data, data)
}

// 3. Navigation Test Template
func test_action_navigates() {
    subject.receive(.action)
    XCTAssertEqual(coordinator.routes.last, .expectedRoute)
}

// 4. ViewInspector Test Template
func test_button_sendsAction() throws {
    let button = try subject.inspect().find(button: "Title")
    try button.tap()
    XCTAssertEqual(processor.actions.last, .expectedAction)
}

// 5. Snapshot Test Template
func test_snapshot_mode() {
    assertSnapshot(of: subject, as: .defaultPortrait)
}
```

### Test Checklist for AI Agents

When writing tests for a component, ensure:

- [ ] Test file named correctly (`ComponentTests.swift`)
- [ ] Test file in same folder as implementation
- [ ] Inherits from `BitwardenTestCase`
- [ ] `setUp()` creates fresh instances
- [ ] `tearDown()` cleans up (sets to `nil`)
- [ ] All public methods tested
- [ ] Error cases tested
- [ ] Edge cases tested
- [ ] Mocks used for dependencies
- [ ] Assertions are specific (not just "not nil")
- [ ] Test names describe behavior (`test_action_outcome`)
- [ ] Tests ordered by function name (see ordering guidelines below)
- [ ] Async tests use `async`/`await`
- [ ] Views tested with ViewInspector AND Snapshots
- [ ] Snapshots include light/dark/accessibility modes

### Test Ordering Guidelines

Tests should be organized to maximize readability and maintainability:

#### Ordering Principle

**Primary Sort**: Alphabetically by the function/method being tested (second part of test name)
**Secondary Sort**: Logically by behavior cluster (not strictly alphabetical)

#### Test Naming Pattern

```
test_<functionName>_<behaviorDescription>
```

- **Part 1**: Always `test_`
- **Part 2**: The function/method/action being tested (e.g., `receive`, `perform`, `loadData`)
- **Part 3**: The behavior being verified (e.g., `updatesState`, `showsError`, `navigates`)

#### Ordering Examples

**✅ Correct Ordering**:

```swift
class ExampleProcessorTests: BitwardenTestCase {
    // Tests for loadData() - grouped together, ordered logically
    func test_loadData_success_updatesState() async { }
    func test_loadData_failure_showsError() async { }
    func test_loadData_emptyResponse_setsEmptyState() async { }

    // Tests for receive(_:) with different actions - grouped by action
    func test_receive_cancelAction_dismissesView() { }
    func test_receive_nextAction_navigates() { }
    func test_receive_nextAction_whenInvalid_showsError() { }
    func test_receive_toggleAction_updatesState() { }
    func test_receive_toggleAction_whenDisabled_doesNothing() { }

    // Tests for saveData() - grouped together
    func test_saveData_success_showsConfirmation() async { }
    func test_saveData_failure_showsError() async { }

    // Tests for validateInput() - grouped together
    func test_validateInput_validEmail_returnsTrue() { }
    func test_validateInput_invalidEmail_returnsFalse() { }
}
```

**❌ Incorrect Ordering**:

```swift
class ExampleProcessorTests: BitwardenTestCase {
    // Bad: Tests scattered, not grouped by function
    func test_loadData_success_updatesState() async { }
    func test_receive_toggleAction_updatesState() { }
    func test_saveData_failure_showsError() async { }
    func test_loadData_failure_showsError() async { }

    // Bad: Strictly alphabetical by behavior ignores logical clustering
    func test_receive_cancelAction_dismissesView() { }
    func test_receive_nextAction_navigates() { }
    func test_receive_toggleAction_updatesState() { }
    func test_receive_toggleAction_whenDisabled_doesNothing() { }
    func test_receive_nextAction_whenInvalid_showsError() { } // Should be with other nextAction tests
}
```

#### Rationale

**Why group by function name?**
- Related tests stay together
- Easy to find all tests for a specific function
- Makes gaps in test coverage obvious

**Why not strict alphabetical on behavior?**
- Logical flow is more important (success → failure → edge cases)
- Related behaviors should cluster together
- "Happy path" tests typically come before error cases

#### Common Grouping Patterns

1. **Success → Failure → Edge Cases**
   ```swift
   func test_fetchData_success_returnsData() async { }
   func test_fetchData_failure_throwsError() async { }
   func test_fetchData_emptyResponse_returnsEmptyArray() async { }
   func test_fetchData_timeout_throwsTimeoutError() async { }
   ```

2. **By Action Type (for receive/perform tests)**
   ```swift
   // Group all tests for the same action together
   func test_receive_submitAction_validInput_savesData() { }
   func test_receive_submitAction_invalidInput_showsError() { }
   func test_receive_submitAction_emptyInput_showsValidationError() { }
   ```

3. **By State Condition**
   ```swift
   func test_appear_authenticated_loadsData() async { }
   func test_appear_unauthenticated_showsLogin() async { }
   func test_appear_offline_showsOfflineMessage() async { }
   ```

#### Special Cases

**Lifecycle Methods**: Group together at the top
```swift
class ExampleTests: BitwardenTestCase {
    // Initialization tests first
    func test_init_setsInitialState() { }
    func test_init_withParameters_configuresCorrectly() { }

    // Then alphabetically by function
    func test_loadData_success() async { }
    // ...
}
```

**Computed Properties**: Group by property name
```swift
func test_isValid_whenAllFieldsPopulated_returnsTrue() { }
func test_isValid_whenMissingFields_returnsFalse() { }
```

#### Quick Reference for AI Agents

When adding a new test:
1. Find the group of tests for the same function/method
2. Add the new test within that group
3. Order within the group by logical flow (not strict alphabetical)
4. If testing a new function, insert the group alphabetically by function name
