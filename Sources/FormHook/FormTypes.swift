//
//  FormTypes.swift
//  swiftui-hooks-form
//
//  Created by Robert on 07/11/2022.
//

import Combine
import SwiftUI

// MARK: - Core Form Types

/// A structure that stores data related to the registration of a field.
public struct RegisterOption<Value> {
    /// An optional integer that represents the ordinal of the field.
    let fieldOrdinal: Int?
    /// The validator used to validate the value of the field.
    let rules: any Validator<Value>
    /// The default value for the field.
    let defaultValue: Value
    /// A boolean value that indicates whether or not the field should be unregistered after it has been registered.
    let shouldUnregister: Bool

    /// Initializes a `RegisterOption` with given parameters. 
    /// - Parameters: 
    ///     - fieldOrdinal: An optional integer that represents the ordinal of the field, defaults to `nil`. 
    ///     - rules: The validator used to validate the value of the field. 
    ///     - defaultValue: The default value for the field. 
    ///     - shouldUnregister: A boolean value that indicates whether or not the field should be unregistered after it has been registered, defaults to `true`.
    public init(fieldOrdinal: Int? = nil, rules: any Validator<Value>, defaultValue: Value, shouldUnregister: Bool = true) {
        self.fieldOrdinal = fieldOrdinal
        self.rules = rules
        self.defaultValue = defaultValue
        self.shouldUnregister = shouldUnregister
    }
}

/// A set of options that can be used when unregistering a field.
public struct UnregisterOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Keep the dirty state of the field.
    public static let keepDirty = UnregisterOption(rawValue: 1 << 0)

    /// Keep the isValid state of the field.
    public static let keepIsValid = UnregisterOption(rawValue: 1 << 1)

    /// Keep the error state of the field.
    public static let keepError = UnregisterOption(rawValue: 1 << 2)

    /// Keep the value of the field.
    public static let keepValue = UnregisterOption(rawValue: 1 << 3)

    /// Keep the default value of the field.
    public static let keepDefaultValue = UnregisterOption(rawValue: 1 << 4)

	/// All options combined into one set. 
	/// This includes `keepDirty`, `keepIsValid`, `keepError`, `keepValue` and `keepDefaultValue`. 
	public static let all: UnregisterOption = [keepDirty, keepIsValid, keepError, keepValue, keepDefaultValue]
}

/// A type that represents a set of reset options for a form.
///
/// ResetOption is an `OptionSet` type that allows you to specify which parts of a form should be reset when the form is reset.
public struct ResetOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Indicates whether the form's `isDirty` flag should be reset when the form is reset. 
    public static let keepDirty = ResetOption(rawValue: 1 << 0)

    /// Indicates whether the form's `isSubmitted` flag should be reset when the form is reset. 
    public static let keepIsSubmitted = ResetOption(rawValue: 1 << 1)

    /// Indicates whether the form's `isValid` flag should be reset when the form is reset. 
    public static let keepIsValid = ResetOption(rawValue: 1 << 2)

    /// Indicates whether any errors associated with fields in the form should be kept when the form is reset. 
    public static let keepErrors = ResetOption(rawValue: 1 << 3)

    /// Indicates whether any values associated with fields in the form should be kept when the form is reset. 
    public static let keepValues = ResetOption(rawValue: 1 << 4)

    /// Indicates whether any default values associated with fields in the form should be kept when the form is reset. 
    public static let keepDefaultValues = ResetOption(rawValue: 1 << 5)

    /// Indicates whether any submit counts associated with fields in the form should be kept when the form is reset. 
     public static let keepSubmitCount = ResetOption(rawValue: 1 << 6)

    /// A convenience option that keeps all properties of a form when it is reset.  Equivalent to setting all other options to true individually.
    public static let all: ResetOption = [keepDirty, keepIsSubmitted, keepIsValid, keepErrors, keepValues, keepDefaultValues, keepSubmitCount]
}

/// A type that represents a set of options for resetting a single field.
public struct SingleResetOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Keeps the dirty state of the field when resetting it.
    public static let keepDirty = SingleResetOption(rawValue: 1 << 0)

    /// Keeps the error state of the field when resetting it.
    public static let keepError = SingleResetOption(rawValue: 1 << 1)

    /// A convenience option that keeps all properties of the field.
    public static let all: SingleResetOption = [keepDirty, keepError]
}

/// Represents a set of options that can be used when setting a value.
public struct SetValueOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Indicates whether the value should be validated before setting it.
    public static let shouldValidate = SetValueOption(rawValue: 1 << 0)

    /// Indicates whether the value should be marked as dirty after setting it.
    public static let shouldDirty = SetValueOption(rawValue: 1 << 1)

    /// A combination of both `shouldValidate` and `shouldDirty` options.
    public static let all: SetValueOption = [shouldValidate, shouldDirty]
}

// MARK: - Field Registration Types

public typealias FieldRegistration<Value> = Binding<Value>

// MARK: - Form Value Types

public typealias FormValue<FieldName> = [FieldName: Any] where FieldName: Hashable

extension FormValue {
    mutating func unioned(_ other: Self) {
        for (key, value) in other {
            updateValue(value, forKey: key)
        }
    }
}

// MARK: - Error Types

/// A generic struct for representing form errors.
/// - Note: `FieldName` must conform to the `Hashable` protocol.
public struct FormError<FieldName>: Equatable where FieldName: Hashable {
    /// The set of fields that have errors.
    public private(set) var errorFields: Set<FieldName>
    /// The messages associated with each field name.
    public private(set) var messages: [FieldName: [String]]

    /// Initializes a new `FormError` instance with the given error fields and messages.
    /// - Parameters: 
    ///   - errorFields: The set of fields that have errors, defaults to an empty set. 
    ///   - messages: The messages associated with each field name, defaults to an empty dictionary. 
    init(errorFields: Set<FieldName> = .init(), messages: [FieldName: [String]] = [:]) {
        self.errorFields = errorFields
        self.messages = messages
    }

    /// Returns the array of strings associated with the given field name, if any exist.
    public subscript(_ name: FieldName) -> [String] {
        messages[name] ?? []
    }

    /// Sets the given array of strings as the message for the given field name and updates its validity accordingly.
    mutating func setMessages(name: FieldName, messages: [String]?, isValid: Bool) {
        if isValid {
            self.errorFields.remove(name)
        } else {
            self.errorFields.insert(name)
        }
        self.messages[name] = messages
    }

    /// Removes the given field from this instance's list of error fields and sets its message to nil, effectively marking it as valid.
    mutating func remove(name: FieldName) {
        setMessages(name: name, messages: nil, isValid: true)
    }

    mutating func removeMessagesOnly(name: FieldName) {
        self.messages[name] = nil
    }

    mutating func removeValidityOnly(name: FieldName) {
        self.errorFields.remove(name)
    }

    /// Returns a new `FormError` instance with the combined error fields and messages of the two given instances.
    func union(_ other: Self) -> Self {
        let errorFields = errorFields.union(other.errorFields)
        var newMessages = messages
        for (key, newValue) in other.messages {
            if let existingValue = newMessages[key] {
                newMessages[key] = existingValue + newValue
            } else {
                newMessages[key] = newValue
            }
        }
        return Self(errorFields: errorFields, messages: newMessages)
    }
}

extension FormError: Error {}

// MARK: - State Types

/// Represents the state of a submission.
public enum SubmissionState: Equatable {

    /// The submission has not been submitted yet.
    case notSubmit

    /// The submission is currently being submitted.
    case submitting

    /// The submission has been successfully submitted.
    case submitted
}

/// A generic struct that holds the state of a form.
/// - Note: `FieldName` must conform to the `Hashable` protocol.
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

    /// A set of dirty fields in the form.
    public internal(set) var dirtyFields: Set<FieldName>

    /// A dictionary of values for each field in the form.
    public internal(set) var formValues: FormValue<FieldName>

    /// A dictionary of default values for each field in the form.
    public internal(set) var defaultValues: FormValue<FieldName>

    /// The current submission state of the form.
    public internal(set) var submissionState: SubmissionState

    /// Whether or not the last submission was successful.
    public internal(set) var isSubmitSuccessful: Bool

    /// The number of times the form has been submitted.
    public internal(set) var submitCount: Int

    /// Whether or not all fields in the form are valid.
    public internal(set) var isValid: Bool

    /// Whether or not the form is currently validating its fields.
    public internal(set) var isValidating: Bool

    /// A dictionary of errors for each field in the form, if any exist. 
    public internal(set) var errors: FormError<FieldName> 

    /// Creates an instance of `FormState` with all properties set to their default values.
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

    /// A boolean value indicating whether the form is dirty.
    ///
    /// This property is `true` if the object has any dirty fields, and `false` otherwise.
    public var isDirty: Bool {
        !dirtyFields.isEmpty
    }

    func getFieldState(name: FieldName) -> FieldState {
        FieldState(
            isDirty: dirtyFields.contains(name),
            isInvalid: errors.errorFields.contains(name),
            error: errors[name]
        )
    }
}

/// A struct that contains the state of a field.
public struct FieldState {

    /// A boolean value indicating whether the field has been modified or not.
    public let isDirty: Bool

    /// A boolean value indicating whether the field is valid or not.
    public let isInvalid: Bool

    /// An array of strings containing any errors associated with the field.
    public let error: [String]
}

protocol FieldProtocol {
    var fieldOrdinal: Int { get }
    var shouldUnregister: Bool { get }
    func computeMessages() async -> (Bool, [String])
}
