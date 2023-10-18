/// A protocol for a `GeneratorRepository` which manages access to the data needed by the UI layer.
///
protocol GeneratorRepository: AnyObject {}

// MARK: - DefaultGeneratorRepository

/// A default implementation of a `GeneratorRepository`.
///
class DefaultGeneratorRepository {}

// MARK: GeneratorRepository

extension DefaultGeneratorRepository: GeneratorRepository {}
