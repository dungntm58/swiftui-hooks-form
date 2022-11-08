//
//  Validators.swift
//  swiftui-hooks-form
//
//  Created by Robert on 12/11/2022.
//

import Foundation

public struct NoopValidator<Value>: Validator {
    public init() {}

    public func validate(_ value: Value) async -> Bool {
        true
    }
}

public struct NotEmptyValidator<Value>: Validator where Value: Collection {
    let messageGenerator: MessageGeneratorFunction<Bool>

    public init(_ messageGenerator: @escaping MessageGeneratorFunction<Bool>) {
        self.messageGenerator = messageGenerator
    }

    public func validate(_ value: Value) async -> Bool {
        !value.isEmpty
    }

    public func generateMessage(result: Bool) -> [String] {
        messageGenerator(result)
    }
}

public struct NotNilValidator<V>: Validator {
    let messageGenerator: MessageGeneratorFunction<Bool>

    public init(_ messageGenerator: @escaping MessageGeneratorFunction<Bool>) {
        self.messageGenerator = messageGenerator
    }

    public func validate(_ value: V?) async -> Bool {
        value != nil
    }

    public func generateMessage(result: Bool) -> [String] {
        messageGenerator(result)
    }
}

public struct RangeValidator<Value>: Validator where Value: Comparable {
    let min: Value?
    let max: Value?
    let messageGenerator: MessageGeneratorFunction<Bool>

    public init(min: Value, max: Value, _ messageGenerator: @escaping MessageGeneratorFunction<Bool>) {
        assert(min <= max)
        self.min = min
        self.max = max
        self.messageGenerator = messageGenerator
    }

    public init(min: Value, _ messageGenerator: @escaping MessageGeneratorFunction<Bool>) {
        self.min = min
        self.max = nil
        self.messageGenerator = messageGenerator
    }

    public init(max: Value?, _ messageGenerator: @escaping MessageGeneratorFunction<Bool>) {
        self.min = nil
        self.max = max
        self.messageGenerator = messageGenerator
    }

    public func validate(_ value: Value) async -> Bool {
        (min.map { value >= $0 } ?? true) && (max.map { value <= $0 } ?? true)
    }

    public func generateMessage(result: Bool) -> [String] {
        messageGenerator(result)
    }
}

public struct LengthRangeValidator<Value>: Validator where Value: Collection {
    let minLength: Int?
    let maxLength: Int?
    let messageGenerator: MessageGeneratorFunction<Bool>

    public init(minLength: Int, maxLength: Int, _ messageGenerator: @escaping MessageGeneratorFunction<Bool>) {
        assert(minLength <= maxLength)
        self.minLength = minLength
        self.maxLength = maxLength
        self.messageGenerator = messageGenerator
    }

    public init(minLength: Int, _ messageGenerator: @escaping MessageGeneratorFunction<Bool>) {
        self.minLength = minLength
        self.maxLength = nil
        self.messageGenerator = messageGenerator
    }

    public init(maxLength: Int, _ messageGenerator: @escaping MessageGeneratorFunction<Bool>) {
        self.minLength = nil
        self.maxLength = maxLength
        self.messageGenerator = messageGenerator
    }

    public func validate(_ value: Value) async -> Bool {
        (minLength.map { value.count >= $0 } ?? true) && (maxLength.map { value.count <= $0 } ?? true)
    }

    public func generateMessage(result: Bool) -> [String] {
        messageGenerator(result)
    }
}

@available(iOS 16.0, *)
public struct RegexMatchingValidator<Value>: Validator where Value: StringProtocol {
    let regex: Regex<Value>
    let messageGenerator: MessageGeneratorFunction<Bool>

    public init(regex: Regex<Value>, _ messageGenerator: @escaping MessageGeneratorFunction<Bool>) {
        self.regex = regex
        self.messageGenerator = messageGenerator
    }

    public func validate(_ value: Value) async -> Bool {
        do {
            return try regex.wholeMatch(in: String(value))?.range == value.startIndex..<value.endIndex
        } catch {
            return false
        }
    }

    public func generateMessage(result: Bool) -> [String] {
        messageGenerator(result)
    }
}

public struct PatternMatchingValidator<Value>: Validator where Value: StringProtocol {
    let pattern: String
    let messageGenerator: MessageGeneratorFunction<Bool>

    public init(pattern: String, _ messageGenerator: @escaping MessageGeneratorFunction<Bool>) {
        self.pattern = pattern
        self.messageGenerator = messageGenerator
    }

    public func validate(_ value: Value) async -> Bool {
        value.range(of: pattern, options: .regularExpression) == value.startIndex..<value.endIndex
    }

    public func generateMessage(result: Bool) -> [String] {
        messageGenerator(result)
    }
}
