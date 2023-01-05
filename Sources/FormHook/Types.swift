//
//  Control.swift
//  swiftui-hooks-form
//
//  Created by Robert on 07/11/2022.
//

import Combine
import SwiftUI

public struct RegisterOption<Value> {
    let rules: any Validator<Value>
    let defaultValue: Value
    let shouldUnregister: Bool

    public init(rules: any Validator<Value>, defaultValue: Value, shouldUnregister: Bool = true) {
        self.rules = rules
        self.defaultValue = defaultValue
        self.shouldUnregister = shouldUnregister
    }
}

public struct UnregisterOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let keepDirty = UnregisterOption(rawValue: 1 << 0)
    public static let keepIsValid = UnregisterOption(rawValue: 1 << 1)
    public static let keepError = UnregisterOption(rawValue: 1 << 2)
    public static let keepValue = UnregisterOption(rawValue: 1 << 3)
    public static let keepDefaultValue = UnregisterOption(rawValue: 1 << 4)
    public static let all: UnregisterOption = [keepDirty, keepIsValid, keepError, keepValue, keepDefaultValue]
}

public struct ResetOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let keepDirty = ResetOption(rawValue: 1 << 0)
    public static let keepIsSubmitted = ResetOption(rawValue: 1 << 1)
    public static let keepIsValid = ResetOption(rawValue: 1 << 2)
    public static let keepErrors = ResetOption(rawValue: 1 << 3)
    public static let keepValues = ResetOption(rawValue: 1 << 4)
    public static let keepDefaultValues = ResetOption(rawValue: 1 << 5)
    public static let keepSubmitCount = ResetOption(rawValue: 1 << 6)
    public static let all: ResetOption = [keepDirty, keepIsSubmitted, keepIsValid, keepErrors, keepValues, keepDefaultValues, keepSubmitCount]
}

public struct SingleResetOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let keepDirty = SingleResetOption(rawValue: 1 << 0)
    public static let keepError = SingleResetOption(rawValue: 1 << 1)
    public static let all: SingleResetOption = [keepDirty, keepError]
}

public struct SetValueOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let shouldValidate = SetValueOption(rawValue: 1 << 0)
    public static let shouldDirty = SetValueOption(rawValue: 1 << 1)
    public static let all: SetValueOption = [shouldValidate, shouldDirty]
}

public typealias FieldRegistration<Value> = Binding<Value>

public typealias FormValue<FieldName> = [FieldName: Any] where FieldName: Hashable

extension FormValue {
    mutating func update(other: Self) {
        for (key, value) in other {
            updateValue(value, forKey: key)
        }
    }
}

public struct FormError<FieldName>: Equatable where FieldName: Hashable {
    public private(set) var errorFields: Set<FieldName>
    public private(set) var messages: [FieldName: [String]]

    init(errorFields: Set<FieldName> = .init(), messages: [FieldName: [String]] = [:]) {
        self.errorFields = errorFields
        self.messages = messages
    }

    public subscript(_ name: FieldName) -> [String]? {
        messages[name]
    }

    mutating func setMessages(name: FieldName, messages: [String]?, isValid: Bool) {
        if isValid {
            self.errorFields.remove(name)
        } else {
            self.errorFields.insert(name)
        }
        self.messages[name] = messages
    }

    mutating func remove(name: FieldName) {
        setMessages(name: name, messages: nil, isValid: true)
    }

    mutating func removeMessagesOnly(name: FieldName) {
        self.messages[name] = nil
    }

    mutating func removeValidityOnly(name: FieldName) {
        self.errorFields.remove(name)
    }

    func rewrite(from other: Self) -> Self {
        let errorFields = errorFields.union(other.errorFields)
        var newMessages = messages
        for (key, newValue) in other.messages {
            newMessages[key] = newValue
        }
        return Self(errorFields: errorFields, messages: newMessages)
    }
}

extension FormError: Error {}

public enum SubmissionState: Equatable {
    case notSubmit
    case submitting
    case submitted
}

public struct FormState<FieldName>: Equatable where FieldName: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dirtyFields == rhs.dirtyFields
        && areEqual(first: lhs.defaultValues, second: rhs.defaultValues)
        && areEqual(first: lhs.formValues, second: rhs.formValues)
        && lhs.submissionState == rhs.submissionState
        && lhs.isSubmitSuccessful == rhs.isSubmitSuccessful
        && lhs.submitCount == rhs.submitCount
        && lhs.isValid == rhs.isValid
        && lhs.isValidating == rhs.isValidating
        && lhs.errors == rhs.errors
    }

    public internal(set) var dirtyFields: Set<FieldName>
    public internal(set) var formValues: FormValue<FieldName>
    public internal(set) var defaultValues: FormValue<FieldName>
    public internal(set) var submissionState: SubmissionState
    public internal(set) var isSubmitSuccessful: Bool
    public internal(set) var submitCount: Int
    public internal(set) var isValid: Bool
    public internal(set) var isValidating: Bool
    public internal(set) var errors: FormError<FieldName>

    init(dirtyFields: Set<FieldName> = .init(),
         formValues: FormValue<FieldName> = [:],
         defaultValues: FormValue<FieldName> = [:],
         submissionState: SubmissionState = .notSubmit,
         isSubmitSuccessful: Bool = false,
         submitCount: Int = 0,
         isValid: Bool = true,
         isValidating: Bool = false,
         errors: FormError<FieldName> = .init()
    ) {
        self.dirtyFields = dirtyFields
        self.formValues = formValues
        self.defaultValues = defaultValues
        self.submissionState = submissionState
        self.isSubmitSuccessful = isSubmitSuccessful
        self.submitCount = submitCount
        self.isValid = isValid
        self.isValidating = isValidating
        self.errors = errors
    }

    public var isDirty: Bool {
        !dirtyFields.isEmpty
    }

    func getFieldState(name: FieldName) -> FieldState {
        FieldState(
            isDirty: dirtyFields.contains(name),
            isInvalid: errors.errorFields.contains(name),
            error: errors[name] ?? []
        )
    }
}

public struct FieldState {
    public let isDirty: Bool
    public let isInvalid: Bool
    public let error: [String]

    init(isDirty: Bool, isInvalid: Bool, error: [String]) {
        self.isDirty = isDirty
        self.isInvalid = isInvalid
        self.error = error
    }
}

protocol FieldProtocol {
    var shouldUnregister: Bool { get }
    func computeMessages() async -> (Bool, [String])
}
