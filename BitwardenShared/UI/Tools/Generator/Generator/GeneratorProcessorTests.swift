import XCTest

@testable import BitwardenShared

class GeneratorProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<GeneratorRoute>!
    var generatorRepository: MockGeneratorRepository!
    var subject: GeneratorProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        generatorRepository = MockGeneratorRepository()

        subject = GeneratorProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                generatorRepository: generatorRepository
            ),
            state: GeneratorState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        generatorRepository = nil
        subject = nil
    }

    // MARK: Tests
}
