// swiftlint:disable:this file_name
import SwiftUI
import ViewInspector
import ViewInspectorTestHelpers
import XCTest

@testable import BitwardenKit

final class ExpandableHeaderViewTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(title:count:buttonAccessibilityIdentifier:content:)` starts in the expanded state.
    @MainActor
    func test_init_withoutBinding_startsExpanded() throws {
        let subject = ExpandableHeaderView(title: "Title", count: 3) {
            Text("Child")
        }

        // The child content is rendered only when `isExpanded` is true, so its presence is a
        // proxy for the initial expansion state.
        XCTAssertNoThrow(try subject.inspect().find(text: "Child"))
    }

    /// `init(title:count:buttonAccessibilityIdentifier:isExpanded:content:)` reflects the caller's
    /// binding value on the first render.
    @MainActor
    func test_init_withBinding_reflectsBindingState() throws {
        let collapsedSubject = ExpandableHeaderView(
            title: "Title",
            count: 3,
            isExpanded: .constant(false),
        ) {
            Text("Hidden child")
        }
        XCTAssertThrowsError(try collapsedSubject.inspect().find(text: "Hidden child"))

        let expandedSubject = ExpandableHeaderView(
            title: "Title",
            count: 3,
            isExpanded: .constant(true),
        ) {
            Text("Visible child")
        }
        XCTAssertNoThrow(try expandedSubject.inspect().find(text: "Visible child"))
    }

    /// Tapping the header button with an external binding writes the toggled value back through
    /// that binding so the caller's persisted storage is kept in sync.
    @MainActor
    func test_init_withBinding_updatesThroughBinding() throws {
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })
        let subject = ExpandableHeaderView(
            title: "Title",
            count: 3,
            isExpanded: binding,
        ) {
            Text("Child")
        }

        let button = try subject.inspect().find(ViewType.Button.self)
        try button.tap()

        XCTAssertFalse(
            isExpanded,
            "Tapping the header should write the toggled value through the caller-supplied binding",
        )
    }

    /// Exercising the header repeatedly must keep the caller's binding coherent across toggles —
    /// i.e. the computed `isExpanded: Binding<Bool>` must continue to resolve to the
    /// `externalIsExpanded` storage on every render, including renders that observe a previously
    /// written value. This guards against regressions where the `withAnimation`-wrapped write
    /// stops propagating after the first toggle (e.g. a future refactor to two disjoint storages
    /// that accidentally captures `externalIsExpanded` by value).
    @MainActor
    func test_init_withBinding_roundTripsAcrossMultipleToggles() throws {
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })
        let subject = ExpandableHeaderView(
            title: "Title",
            count: 3,
            isExpanded: binding,
        ) {
            Text("Child")
        }

        for expectedAfterTap in [false, true, false] {
            let button = try subject.inspect().find(ViewType.Button.self)
            try button.tap()
            XCTAssertEqual(
                isExpanded,
                expectedAfterTap,
                "Each tap must write back through the caller-supplied binding; expected \(expectedAfterTap)",
            )
        }
    }
}
