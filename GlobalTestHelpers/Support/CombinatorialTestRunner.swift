/// Helper that runs combinatorial tests.
enum CombinatorialTestRunner {
    /// Executes `run` with each value of the `values` array.
    /// - Parameters:
    ///   - values: Values to pass as parameter to the execution
    ///   - run: Closure to run with the parameter.
    static func runWithEachValue<T>(values: [T], run: (T) -> Void) {
        for val in values {
            run(val)
        }
    }

    /// Executes `run` with each combination of values of the `values` arrays.
    /// - Parameters:
    ///   - values1: Values to pass as first parameter to the execution
    ///   - values2: Values to pass as second parameter to the execution
    ///   - run: Closure to run with the parameters.
    static func runCombined<T, U>(
        values1: [T],
        values2: [U],
        run: (T, U) -> Void
    ) {
        for val1 in values1 {
            for val2 in values2 {
                run(val1, val2)
            }
        }
    }

    /// Executes `run` with each combination of values of the `values` arrays.
    /// - Parameters:
    ///   - values1: Values to pass as first parameter to the execution
    ///   - values2: Values to pass as second parameter to the execution
    ///   - values3: Values to pass as third parameter to the execution
    ///   - run: Closure to run with the parameters.
    static func runCombined<T, U, V>(
        values1: [T],
        values2: [U],
        values3: [V],
        run: (T, U, V) -> Void
    ) {
        for val1 in values1 {
            for val2 in values2 {
                for val3 in values3 {
                    run(val1, val2, val3)
                }
            }
        }
    }

    /// Executes `run` with each combination of values of the `values` arrays.
    /// - Parameters:
    ///   - values1: Values to pass as first parameter to the execution
    ///   - values2: Values to pass as second parameter to the execution
    ///   - values3: Values to pass as third parameter to the execution
    ///   - values4: Values to pass as fourth parameter to the execution
    ///   - run: Closure to run with the parameters.
    static func runCombined<T, U, V, W>(
        values1: [T],
        values2: [U],
        values3: [V],
        values4: [W],
        run: (T, U, V, W) -> Void
    ) {
        for val1 in values1 {
            for val2 in values2 {
                for val3 in values3 {
                    for val4 in values4 {
                        run(val1, val2, val3, val4)
                    }
                }
            }
        }
    }
}
