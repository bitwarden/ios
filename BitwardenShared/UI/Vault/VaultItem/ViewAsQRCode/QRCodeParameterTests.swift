import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - QRCodeParameterTests

class QRCodeParameterTests: BitwardenTestCase {
    /// A `QRCodeParameter` has a localized title.
    func test_parameterTitle() {
        let subject = QRCodeParameter(
            name: Localizations.ssid,
            options: [.username]
        )

        XCTAssertEqual(subject.parameterTitle, Localizations.fieldFor(Localizations.ssid))
    }

    /// `QRCodeParameter.init()` does not include `.none` if isOptional is false.
    func test_isOptional_false() {
        let subject = QRCodeParameter(
            name: Localizations.ssid,
            options: [.username],
            isOptional: false
        )

        XCTAssertEqual(subject.options, [.username])
    }

    /// `QRCodeParameter.init()` includes `.none` if isOptional is true.
    func test_isOptional_true() {
        let subject = QRCodeParameter(
            name: Localizations.ssid,
            options: [.username],
            isOptional: true
        )

        XCTAssertEqual(subject.options, [.none, .username])
    }

    /// `QRCodeParameter.init()` sets the initial selected to the first item on the priority list
    /// that is available.
    func test_priority_available() {
        let subject = QRCodeParameter(
            name: Localizations.ssid,
            options: [.username, .password],
            fieldPriority: [.notes, .password]
        )

        XCTAssertEqual(subject.selected, .password)
    }

    /// `QRCodeParameter.init()` sets the initial selected to `.none`
    /// If nothing on the priority list is available
    /// and the parameter is optional.
    func test_priority_unavailable_optional() {
        let subject = QRCodeParameter(
            name: Localizations.ssid,
            options: [.username, .password],
            fieldPriority: [.notes],
            isOptional: true
        )

        XCTAssertEqual(subject.selected, .none)
    }

    /// `QRCodeParameter.init()` sets the initial selected to the first option
    /// If nothing on the priority list is available
    /// and the parameter is not optional.
    func test_priority_unavailable_required() {
        let subject = QRCodeParameter(
            name: Localizations.ssid,
            options: [.password, .username],
            fieldPriority: [.notes],
            isOptional: false
        )

        XCTAssertEqual(subject.selected, .password)
    }

    /// `QRCodeParameter.init()` sets the initial selected to `.none`
    /// If nothing on the priority list is available
    /// and the parameter is not optional
    /// and there are no options to otherwise pick from.
    func test_priority_unavailable_noOptions() {
        let subject = QRCodeParameter(
            name: Localizations.ssid,
            options: [],
            fieldPriority: [.notes],
            isOptional: false
        )

        XCTAssertEqual(subject.selected, .none)
    }

    /// `QRCodeParameter.init()` sets the initial selected to `.none`
    /// If there is no priority list
    /// and the parameter is optional.
    func test_noPriority_optional() {
        let subject = QRCodeParameter(
            name: Localizations.ssid,
            options: [.username, .password],
            isOptional: true
        )

        XCTAssertEqual(subject.selected, .none)
    }

    /// `QRCodeParameter.init()` sets the initial selected to the first option
    /// If there is no priority list
    /// and the parameter is not optional.
    func test_noPriority_required() {
        let subject = QRCodeParameter(
            name: Localizations.ssid,
            options: [.notes, .password],
            isOptional: false
        )

        XCTAssertEqual(subject.selected, .notes)
    }

    /// `QRCodeParameter.init()` sets the initial selected to `.none`
    /// If there is no priority list
    /// and the parameter is not optional
    /// and there are no options to otherwise pick from.
    func test_noPriority_noOptions() {
        let subject = QRCodeParameter(
            name: Localizations.ssid,
            options: [],
            isOptional: false
        )

        XCTAssertEqual(subject.selected, .none)
    }
}
