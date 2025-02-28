import Foundation
import XCTest

@testable import AuthenticatorShared

@MainActor
class StoreTests: AuthenticatorTestCase {
    var processor: MockProcessor<TestState, TestAction, TestEffect>!
    var subject: Store<TestState, TestAction, TestEffect>!

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: TestState())
        subject = Store(processor: processor)
    }

    /// `send(_:)` forwards the action to the processor for processing.
    func testSendAction() {
        subject.send(.increment)
        XCTAssertEqual(processor.dispatchedActions, [.increment])
        processor.dispatchedActions.removeAll()

        subject.send(.decrement)
        XCTAssertEqual(processor.dispatchedActions, [.decrement])
    }

    /// `perform(_:)` forwards the effect to the processor for performing.
    func testPerformEffect() async {
        await subject.perform(.something)
        XCTAssertEqual(processor.effects, [.something])
    }

    /// `child(_:)` creates a child store that maps actions, state, and effects from its parent.
    func testChildStore() async {
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
    func testBinding() {
        let binding = subject.binding(get: { $0.counter }, send: { .counterChanged($0) })

        XCTAssertEqual(binding.wrappedValue, 0)

        binding.wrappedValue = 1
        XCTAssertEqual(processor.dispatchedActions, [.counterChanged(1)])
        processor.dispatchedActions.removeAll()

        binding.wrappedValue = 20
        XCTAssertEqual(processor.dispatchedActions, [.counterChanged(20)])
    }

    /// `binding(get:)` creates a binding from a value in the state that does not update the state when the binding's
    /// value is changed.
    func testBindingGetOnly() {
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
}

struct TestState: Equatable {
    var child = ChildState()
    var counter = 0
}
