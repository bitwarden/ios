import BitwardenSdk
import XCTest

@testable import BitwardenShared

class GeneratorHistoryProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<GeneratorRoute>!
    var generatorRepository: MockGeneratorRepository!
    var subject: GeneratorHistoryProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        generatorRepository = MockGeneratorRepository()

        subject = GeneratorHistoryProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                generatorRepository: generatorRepository
            ),
            state: GeneratorHistoryState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        generatorRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
