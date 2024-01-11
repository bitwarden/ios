import Foundation
import XCTest

@testable import BitwardenShared

// MARK: - StoreTests

@MainActor
class StoreTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<TestState, TestAction, TestEffect>!
    var subject: Store<TestState, TestAction, TestEffect>!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: TestState())
        subject = Store(processor: processor)
    }

    // MARK: Tests

    /// `send(_:)` forwards the action to the processor for processing.
    func test_send_action() {
        subject.send(.increment)
        XCTAssertEqual(processor.dispatchedActions, [.increment])
        processor.dispatchedActions.removeAll()

        subject.send(.decrement)
        XCTAssertEqual(processor.dispatchedActions, [.decrement])
    }

    /// `perform(_:)` forwards the effect to the processor for performing.
    func test_perform_effect() async {
        await subject.perform(.something)
        XCTAssertEqual(processor.effects, [.something])
    }

    /// `child(_:)` creates a child store that maps actions, state, and effects from its parent.
    func test_child() async {
        let childStore = subject.child(state: { $0.child }, mapAction: { .child($0) }, mapEffect: { .child($0) })

        XCTAssertEqual(childStore.state.value, "🐣")

        childStore.send(.updateValue("🦜"))
        XCTAssertEqual(processor.dispatchedActions, [.child(.updateValue("🦜"))])

        await childStore.perform(.something)
        XCTAssertEqual(processor.effects, [.child(.something)])

        processor.state.child.value = "🦜"
        XCTAssertEqual(childStore.state.value, "🦜")
    }

    /// `binding(get:send:)` creates a binding from a value in the state and sends an action to the
    /// processor when the binding's value changes.
    func test_binding() {
        let binding = subject.binding(get: { $0.counter }, send: { .counterChanged($0) })

        XCTAssertEqual(binding.wrappedValue, 0)

        binding.wrappedValue = 1
        XCTAssertEqual(processor.dispatchedActions, [.counterChanged(1)])
        processor.dispatchedActions.removeAll()

        binding.wrappedValue = 20
        XCTAssertEqual(processor.dispatchedActions, [.counterChanged(20)])
    }

    /// `bindingAsync(get:perform:)` creates a binding from a value in the state and performs an effect on the
    /// processor when the binding's value changes.
    func test_bindingAsync() {
        let binding = subject.bindingAsync(
            get: { $0.isToggleOn },
            perform: { value in
                .toggleFlipped(value)
            }
        )

        XCTAssertEqual(binding.wrappedValue, false)

        binding.wrappedValue = true
        waitFor(!processor.effects.isEmpty)
        XCTAssertEqual(processor.effects, [.toggleFlipped(true)])
        processor.effects.removeAll()

        binding.wrappedValue = false
        waitFor(!processor.effects.isEmpty)
        XCTAssertEqual(processor.effects, [.toggleFlipped(false)])
    }

    /// `binding(get:)` creates a binding from a value in the state that does not update the state when the binding's
    /// value is changed.
    func test_binding_getOnly() {
        let binding = subject.binding(get: { $0.counter })

        XCTAssertEqual(binding.wrappedValue, 0)

        binding.wrappedValue = 1
        XCTAssertEqual(processor.dispatchedActions, [])
        XCTAssertEqual(processor.state.counter, 0)
    }
}

enum ChildAction: Equatable {
    case updateValue(String)
}

struct ChildState: Equatable {
    var value = "🐣"
}

enum ChildEffect: Equatable {
    case something
}

enum TestAction: Equatable {
    case child(ChildAction)
    case counterChanged(Int)
    case decrement
    case increment
}

enum TestEffect: Equatable {
    case child(ChildEffect)
    case something
    case toggleFlipped(Bool)
}

struct TestState: Equatable {
    var child = ChildState()
    var counter = 0
    var isToggleOn = false
}
