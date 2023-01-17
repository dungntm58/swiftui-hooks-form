//
//  CompoundValidator.swift
//  swiftui-hooks-form
//
//  Created by Robert on 12/11/2022.
//

import Foundation

extension Validator {
    /// Takes a list of validators and returns a compound validator that validates the value with all the validators and returns true if all the validators return true.
    /// - Parameters: 
    ///   - shouldGetAllMessages: A Boolean value indicating whether to return all messages from the validators or just the first one. Defaults to `false`.
    ///   - validator: A variadic list of `Validator`s to be combined with this one. All must have the same `Value` type as this one.
    /// - Returns: A compound `Validator` that combines this one with the given ones using an AND operator.
    public func and<V>(shouldGetAllMessages: Bool = false, validator: V...) -> some Validator<Value> where V: Validator, V.Value == Value {
        CompoundValidator<Value>(operator: .and, shouldGetAllMessages: shouldGetAllMessages, validator: [eraseToAnyValidator()] + validator.map { $0.eraseToAnyValidator() })
    }

    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    // Takes a list of validators and returns a compound validator that validates the value with all the validators and returns true if all the validators return true.
    /// - Parameters: 
    ///   - shouldGetAllMessages: A Boolean value indicating whether to return all messages from the validators or just the first one. Defaults to `false`.
    ///   - validator: A variadic list of `Validator`s to be combined with this one.
    /// - Returns: A compound `Validator` that combines this one with the given ones using an AND operator.
    public func and(shouldGetAllMessages: Bool = false, validator: any Validator<Value>...) -> some Validator<Value> {
        CompoundValidator<Value>(operator: .and, shouldGetAllMessages: shouldGetAllMessages, validator: ([self] + validator).map { $0.eraseToAnyValidator() })
    }

    /// Takes a list of validators and returns a compound validator that validates the value with all the validators and returns true if one of the validators return true.
    /// - Parameters: 
    ///   - shouldGetAllMessages: A Boolean value indicating whether to return all messages from the validators or just the first one. Defaults to `false`.
    ///   - validator: A variadic list of `Validator`s to be combined with this one. All must have the same `Value` type as this one.
    /// - Returns: A compound `Validator` that combines this one with the given ones using an OR operator.
    public func or<V>(shouldGetAllMessages: Bool = false, validator: V...) -> some Validator<Value> where V: Validator, V.Value == Value {
        CompoundValidator<Value>(operator: .or, shouldGetAllMessages: shouldGetAllMessages, validator: [eraseToAnyValidator()] + validator.map { $0.eraseToAnyValidator() })
    }

    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    /// Takes a list of validators and returns a compound validator that validates the value with all the validators and returns true if one of the validators return true.
    /// - Parameters: 
    ///   - shouldGetAllMessages: A Boolean value indicating whether to return all messages from the validators or just the first one. Defaults to `false`.
    ///   - validator: A variadic list of `Validator`s to be combined with this one.
    /// - Returns: A compound `Validator` that combines this one with the given ones using an OR operator.
    public func or(shouldGetAllMessages: Bool = false, validator: any Validator<Value>...) -> some Validator<Value> {
        CompoundValidator<Value>(operator: .or, shouldGetAllMessages: shouldGetAllMessages, validator: ([self] + validator).map { $0.eraseToAnyValidator() })
    }

    /// Creates a validator that asynchronously transforms the input using the given closure before validating it.
    /// - Parameters: 
    ///   - handler: A closure that asynchronously transforms the input.
    /// - Returns: A validator that asynchronously transforms the input using the given closure before validating it.
    public func preMap<Input>(_ handler: @escaping (Input) async -> Value) -> some Validator<Input> {
        PreMapValidator<Input, Result, Value>(mapHandler: handler, validator: self)
    }
}

private enum CompoundValidatorOperator {
    case and
    case or
}

private struct CompoundValidator<Value>: Validator {
    let validators: [AnyValidator]
    let `operator`: CompoundValidatorOperator
    let shouldGetAllMessages: Bool

    init(operator: CompoundValidatorOperator, shouldGetAllMessages: Bool, validator: [AnyValidator]) {
        self.validators = validator.map { $0.eraseToAnyValidator() }
        self.operator = `operator`
        self.shouldGetAllMessages = shouldGetAllMessages
    }

    func validate(_ value: Value) async -> CompoundValidationResult {
        await withTaskGroup(of: ValidatorResultPair.self) { group in
            validators.forEach { validator in
                group.addTask {
                    let result = await validator.validate(value)
                    return (validator, result)
                }
            }
            if shouldGetAllMessages {
                var isValid: Bool
                var results: [ValidatorResultPair] = []
                switch `operator` {
                case .and:
                    isValid = true
                    for await resultPair in group {
                        results.append(resultPair)
                        if !resultPair.0.isValid(result: resultPair.1) {
                            isValid = false
                        }
                    }
                case .or:
                    isValid = false
                    for await resultPair in group {
                        results.append(resultPair)
                        if resultPair.0.isValid(result: resultPair.1) {
                            isValid = true
                        }
                    }
                }
                return CompoundValidationResult(
                    messages: results.flatMap { (validator, result) in validator.generateMessage(result: result) },
                    boolValue: isValid
                )
            }
            var results: [ValidatorResultPair] = []
            switch `operator` {
            case .and:
                for await resultPair in group {
                    results.append(resultPair)
                    guard resultPair.0.isValid(result: resultPair.1) else {
                        return CompoundValidationResult(
                            messages: results.flatMap { (validator, result) in validator.generateMessage(result: result) },
                            boolValue: false
                        )
                    }
                }
                return CompoundValidationResult(
                    messages: results.flatMap { (validator, result) in validator.generateMessage(result: result) },
                    boolValue: true
                )
            case .or:
                for await resultPair in group {
                    results.append(resultPair)
                    if resultPair.0.isValid(result: resultPair.1) {
                        return CompoundValidationResult(
                            messages: results.flatMap { (validator, result) in validator.generateMessage(result: result) },
                            boolValue: true
                        )
                    }
                }
                return CompoundValidationResult(
                    messages: results.flatMap { (validator, result) in validator.generateMessage(result: result) },
                    boolValue: false
                )
            }
        }
    }
}

private typealias ValidatorResultPair = (AnyValidator, Any)

private struct CompoundValidationResult: BoolConvertible, MessageGenerator {
    let messages: [String]
    let boolValue: Bool
}

private struct PreMapValidator<Value, Result, Output>: Validator {
    let mapHandler: (Value) async -> Output
    let originValidator: AnyValidator

    init<OriginValidator>(mapHandler: @escaping (Value) async -> Output, validator: OriginValidator) where OriginValidator: Validator, OriginValidator.Value == Output {
        self.mapHandler = mapHandler
        self.originValidator = validator.eraseToAnyValidator()
    }

    func isValid(result: Result) -> Bool {
        originValidator.isValid(result: result)
    }

    func generateMessage(result: Result) -> [String] {
        originValidator.generateMessage(result: result)
    }

    func validate(_ value: Value) async -> Result {
        await originValidator.validate(mapHandler(value)) as! Result
    }
}
