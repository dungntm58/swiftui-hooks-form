//
//  Validator.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation

public typealias ValidatorFunction<Value, Result> = (Value) async -> Result
public typealias MessageGeneratorFunction<Result> = (Result) -> [String]

/// `BoolConvertible` is a protocol used to represent a type that can be converted to a boolean value.
public protocol BoolConvertible {
    /// A boolean value representing the instance.
    var boolValue: Bool { get }
}

extension Bool: BoolConvertible {
    public var boolValue: Bool { self }
}

/// A protocol that defines a type that provides messages.
///
/// The `MessageGenerator` protocol is used to define a type that provides messages. It requires conforming types to provide an array of strings.
public protocol MessageGenerator {
    /// An array of strings representing the messages provided by the conforming type.
    var messages: [String] { get }
}

/// A protocol used to validate a value of type `Value` and return a result of type `Result`.
public protocol Validator<Value> {
    /// The type of value to be validated.
    associatedtype Value

    /// The type of result returned from the validation.
    associatedtype Result

    /// Validates the given value asynchronously and returns a result.
    /// - Parameter value: The value to be validated.
    func validate(_ value: Value) async -> Result

    /// Checks whether the given result is valid or not.
    /// - Parameter result: The result to be checked.
    func isValid(result: Result) -> Bool

    /// Generates an array of messages based on the given result.
    /// - Parameter result: The result used to generate messages.
    func generateMessage(result: Result) -> [String]
}

extension Validator {
    public func isValid(_ value: Value) async -> Bool {
        let result = await validate(value)
        return isValid(result: result)
    }

    public func isValid(result: Result) -> Bool where Result: BoolConvertible {
        result.boolValue
    }

    public func isValid(result: Result) -> Bool where Result == BoolConvertible {
        result.boolValue
    }

    public func generateMessage(result: Result) -> [String] where Result: MessageGenerator {
        result.messages
    }

    public func generateMessage(result: Result) -> [String] where Result == MessageGenerator {
        result.messages
    }

    public func computeMessage(value: Value) async -> (Bool, [String]) {
        let result = await validate(value)
        return (isValid(result: result), generateMessage(result: result))
    }

    /// Erases a `Validator` to an `AnyValidator`.
    /// - Returns: An erased `AnyValidator` that wraps the receiver.
    public func eraseToAnyValidator() -> AnyValidator {
        .init(self)
    }
}

/// A type-erased validator that can be used to wrap any type of validator.
public struct AnyValidator: Validator {
    fileprivate let box: AnyValidatorBox

    init<V>(_ validator: V) where V: Validator {
        if let v = validator as? AnyValidator {
            self = v
        } else {
            self.box = Box(validator)
        }
    }

    /// Initializes a new instance of `AnyValidator` with the specified validation function and message generator function. 
    /// - Parameter validateFunction: The validation function to use for validation. 
    /// - Parameter messageGenerator: The message generator function to use for generating messages. Defaults to an empty array.
    public init<Value, Result>(
        _ validateFunction: @escaping ValidatorFunction<Value, Result>,
        messageGenerator: @escaping MessageGeneratorFunction<Result> = { _ in [] }
    ) where Result: BoolConvertible {
        self.box = HandlerBox(validateFunction, messageGenerator: messageGenerator)
    }

    /// Initializes a new instance of `AnyValidatior` with the specified validation function and message generator function for boolean convertible results. 
    /// - Parameter validateFunction: The validation function to use for validation. 
    /// - Parameter messageGenerator: The message generator function to use for generating messages. Defaults to an empty array.
    public init<Value>(
        _ validateFunction: @escaping ValidatorFunction<Value, BoolConvertible>,
        messageGenerator: @escaping MessageGeneratorFunction<BoolConvertible> = { _ in [] }
    ) {
        self.box = BoolConvertibleHandlerBox(validateFunction, messageGenerator: messageGenerator)
    }

    public func validate(_ value: Any) async -> Any {
        await box.validate(value)
    }

    public func isValid(result: Any) -> Bool {
        box.isValid(result: result)
    }

    public func generateMessage(result: Any) -> [String] {
        box.generateMessage(result: result)
    }
}

private protocol AnyValidatorBox {
    func validate(_ value: Any) async -> Any
    func isValid(result: Any) -> Bool
    func generateMessage(result: Any) -> [String]
}

private struct Box<Base>: AnyValidatorBox where Base: Validator {
    let base: Base

    init(_ base: Base) {
        self.base = base
    }

    func validate(_ value: Any) async -> Any {
        guard let value = value as? Base.Value else {
            assertionFailure("It must be a value of type \(Base.Value.self)")
            return false
        }
        return await base.validate(value)
    }

    func isValid(result: Any) -> Bool {
        guard let result = result as? Base.Result else {
            assertionFailure("It must be a value of type \(Base.Result.self)")
            return false
        }
        return base.isValid(result: result)
    }

    func generateMessage(result: Any) -> [String] {
        guard let result = result as? Base.Result else {
            assertionFailure("It must be a value of type \(Base.Result.self)")
            return []
        }
        return base.generateMessage(result: result)
    }
}

private struct HandlerBox<Value, Result>: AnyValidatorBox where Result: BoolConvertible {
    let validateFunction: ValidatorFunction<Value, Result>
    let messageGenerator: MessageGeneratorFunction<Result>

    init(_ validateFunction: @escaping ValidatorFunction<Value, Result>, messageGenerator: @escaping MessageGeneratorFunction<Result>) {
        self.validateFunction = validateFunction
        self.messageGenerator = messageGenerator
    }

    func validate(_ value: Any) async -> Any {
        guard let value = value as? Value else {
            assertionFailure("It must be a value of type \(Value.self)")
            return false
        }
        return await validateFunction(value)
    }

    func isValid(result: Any) -> Bool {
        guard let result = result as? Result else {
            assertionFailure("It must be a value of type \(Result.self)")
            return false
        }
        return result.boolValue
    }

    func generateMessage(result: Any) -> [String] {
        guard let result = result as? Result else {
            assertionFailure("It must be a value of type \(Result.self)")
            return []
        }
        return messageGenerator(result)
    }
}

private struct BoolConvertibleHandlerBox<Value>: AnyValidatorBox {
    let validateFunction: ValidatorFunction<Value, BoolConvertible>
    let messageGenerator: MessageGeneratorFunction<BoolConvertible>

    init(
        _ validateFunction: @escaping ValidatorFunction<Value, BoolConvertible>,
        messageGenerator: @escaping MessageGeneratorFunction<BoolConvertible>
    ) {
        self.validateFunction = validateFunction
        self.messageGenerator = messageGenerator
    }

    func validate(_ value: Any) async -> Any {
        guard let value = value as? Value else {
            assertionFailure("It must be a value of type \(Value.self)")
            return false
        }
        return await validateFunction(value)
    }

    func isValid(result: Any) -> Bool {
        guard let result = result as? BoolConvertible else {
            assertionFailure("It must be a value of type BoolConvertible")
            return false
        }
        return result.boolValue
    }

    func generateMessage(result: Any) -> [String] {
        guard let result = result as? BoolConvertible else {
            assertionFailure("It must be a value of type BoolConvertible")
            return []
        }
        return messageGenerator(result)
    }
}
