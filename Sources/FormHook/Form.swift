//
//  UseForm.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import SwiftUI
import Hooks

public struct Rule<FieldName, Value> where FieldName: Hashable, Value: Comparable {
    public let required: Bool = true
    public let min: Value?
    public let max: Value?
    public let minLength: Int?
    public let maxLength: Int?
    public let pattern: String?
    public let validate: [FieldName: AnyValidator]?
}

public struct RegisterOption<FieldName, Value> where FieldName: Hashable, Value: Comparable {
    public let rule: Rule<FieldName, Value>
    public let value: ((Any) -> Value)?
    public let shouldUnregister: Bool = false
    public let onChange: (() -> Void)?
    public let onBlur: (() -> Void)?
    public let disabled: Bool = false
}

public struct UnregisterOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let keepDirty = UnregisterOption(rawValue: 1 << 0)
    public static let keepTouched = UnregisterOption(rawValue: 1 << 1)
    public static let keepIsValid = UnregisterOption(rawValue: 1 << 2)
    public static let keepError = UnregisterOption(rawValue: 1 << 3)
    public static let keepValue = UnregisterOption(rawValue: 1 << 4)
    public static let keepDefaultValue = UnregisterOption(rawValue: 1 << 5)
    public static let all: UnregisterOption = [keepDirty, keepTouched, keepIsValid, keepError, keepValue, keepDefaultValue]
}

public struct ResetOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let keepDirty = ResetOption(rawValue: 1 << 0)
    public static let keepDirtyValues = ResetOption(rawValue: 1 << 1)
    public static let keepTouched = ResetOption(rawValue: 1 << 2)
    public static let keepIsSubmitted = ResetOption(rawValue: 1 << 3)
    public static let keepIsValid = ResetOption(rawValue: 1 << 4)
    public static let keepErrors = ResetOption(rawValue: 1 << 5)
    public static let keepValues = ResetOption(rawValue: 1 << 6)
    public static let keepDefaultValues = ResetOption(rawValue: 1 << 7)
    public static let all: ResetOption = [keepDirty, keepDirtyValues, keepTouched, keepIsSubmitted, keepIsValid, keepErrors, keepValues, keepDefaultValues]
}

public struct SingleResetOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let keepDirty = SingleResetOption(rawValue: 1 << 0)
    public static let keepTouched = SingleResetOption(rawValue: 1 << 1)
    public static let keepError = SingleResetOption(rawValue: 1 << 2)
    public static let defaultValue = SingleResetOption(rawValue: 1 << 3)
    public static let all: SingleResetOption = [keepDirty, keepTouched, keepError, defaultValue]
}

public struct SetValueOption: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let shouldValidate = SetValueOption(rawValue: 1 << 0)
    public static let shouldDirty = SetValueOption(rawValue: 1 << 1)
    public static let shouldTouch = SetValueOption(rawValue: 1 << 2)
    public static let all: SetValueOption = [shouldValidate, shouldDirty, shouldTouch]
}

public struct FieldError {
    public enum `Type` {
        case custom
    }

    public let type: `Type`
    public let message: String?
}

public struct Form<FieldName> where FieldName: Hashable {
    let mode: Mode
    let reValidateMode: ReValidateMode
    let defaultValues: [FieldName: Any]?
    let stateChanged: (FormState<FieldName>, Bool) -> Void

    public let formState: FormState<FieldName>

    init(initialState: FormState<FieldName>, mode: Mode, reValidateMode: ReValidateMode, defaultValues: [FieldName: Any]?, stateChanged: @escaping (FormState<FieldName>, Bool) -> Void) {
        self.formState = initialState
        self.mode = mode
        self.reValidateMode = reValidateMode
        self.defaultValues = defaultValues
        self.stateChanged = stateChanged
    }

    public func register<Value>(name: FieldName, options: RegisterOption<FieldName, Value>) -> (onChange: () -> Void, onBlur: () -> Void, name: FieldName) where Value: Comparable {
        fatalError()
    }

    public func unregister(names: [FieldName], options: UnregisterOption = []) {
        
    }

    public func unregister(name: FieldName..., options: UnregisterOption = []) {
        unregister(names: name, options: options)
    }

    public func watch(name: FieldName..., handle: (Any?, String?, String?) -> Void) {
        
    }

    public func handleSubmit(_ submit: (Any?) -> Void) {
        
    }

    public func reset(values: [FieldName: Any], options: ResetOption = []) {
        
    }

    public func reset(name: FieldName, options: SingleResetOption = []) {
        
    }

    public func setError(name: FieldName, error: FieldError, shouldFocus: Bool = false) {
        
    }

    public func clearErrors(names: [FieldName]) {
        
    }

    public func clearErrors(name: FieldName...) {
        clearErrors(names: name)
    }

    public func setValue(name: FieldName, value: Any, options: SetValueOption = []) {
        
    }

    public func setFocus(name: FieldName, shouldSelect: Bool = true) {
        
    }

    public func getValues(keyPath: AnyKeyPath) -> Any {
        fatalError()
    }

    public func getFieldState(name: FieldName, formState: FormState<FieldName>? = nil) {
        let formState = formState ?? self.formState
        
    }

    public func trigger(names: [FieldName]) {
        
    }

    public func trigger(name: FieldName...) {
        trigger(names: name)
    }
}

public struct FormState<FieldName> where FieldName: Hashable {
    public private(set) var isDirty: Bool = false
    public private(set) var dirtyFields: [FieldName] = []
    public private(set) var touchedFields: [FieldName] = []
    public private(set) var defaultValues: [FieldName: Any]? = nil
    public private(set) var isSubmitted: Bool = false
    public private(set) var isSubmitSuccessful: Bool = false
    public private(set) var isSubmitting: Bool = false
    public private(set) var submitCount: Int = 0
    public private(set) var isValid: Bool = true
    public private(set) var isValidating: Bool = true
    public private(set) var errors: [FieldName: String]? = nil
}

public struct FieldState {
    public private(set) var isDirty: Bool = false
    public private(set) var isTouched: Bool = false
    public private(set) var isInvalid: Bool = false
    public private(set) var error: String?
}
