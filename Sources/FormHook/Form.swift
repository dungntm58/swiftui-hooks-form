//
//  UseForm.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import SwiftUI
import Hooks

public class FormControl<FieldName> where FieldName: Hashable {
    var options: FormOption<FieldName>
    var fields: [FieldName: FieldProtocol]
    @MainActor @Binding
    private(set) public var formState: FormState<FieldName>
    var instantFormState: FormState<FieldName>

    init(options: FormOption<FieldName>, formState: Binding<FormState<FieldName>>) {
        self.options = options
        self.fields = [:]
        self._formState = formState
        self.instantFormState = formState.wrappedValue
    }

    public func register<Value>(name: FieldName, options: RegisterOption<Value>) -> FieldRegistration<Value> {
        self.instantFormState.formValues[name] = options.defaultValue
        self.instantFormState.defaultValues[name] = options.defaultValue
        let field: Field<Value>
        if let f = fields[name] as? Field<Value> {
            field = f
            field.options = options
        } else {
            field = Field(name: name, options: options, control: self)
            fields[name] = field
        }
        return field.value
    }

    public func unregister(names: [FieldName], options: UnregisterOption = []) async {
        if self.options.shouldUnregister {
            names.forEach { fields[$0] = nil }
        }
        if !options.contains(.keepValue) {
            names.forEach { instantFormState.formValues[$0] = nil }
        }
        if !options.contains(.keepError) {
            names.forEach { instantFormState.errors.removeMessagesOnly(name: $0) }
        }
        if !options.contains(.keepDirty) {
            names.forEach { instantFormState.dirtyFields.remove($0) }
        }
        if !self.options.shouldUnregister && !options.contains(.keepDefaultValue) {
            names.forEach { instantFormState.defaultValues[$0] = nil }
        }
        if options.contains(.keepIsValid) {
            return await syncFormState()
        }
        names.forEach { instantFormState.errors.removeValidityOnly(name: $0) }
        await updateValid()
    }

    public func unregister(name: FieldName..., options: UnregisterOption = []) async {
        await unregister(names: name, options: options)
    }

    public func handleSubmit(onValid: @escaping (FormValue<FieldName>, FormError<FieldName>) async throws -> Void, onInvalid: ((FormValue<FieldName>, FormError<FieldName>) async throws -> Void)? = nil) async throws {
        let preservedSubmissionState = instantFormState.submissionState
        instantFormState.submissionState = .submitting
        let errors: FormError<FieldName>
        var isOveralValid: Bool
        if options.mode.contains(.onSubmit) {
            instantFormState.isValidating = true
            await syncFormState()
            (isOveralValid, errors) = await withTaskGroup(of: KeyValidationResult.self) { group -> (Bool, FormError<FieldName>) in
                var errorFields: Set<FieldName> = .init()
                var messages: [FieldName: [String]] = [:]
                var isOveralValid = true

                for (key, field) in fields {
                    group.addTask {
                        let (isValid, messages) = await field.computeMessages()
                        return KeyValidationResult(key: key, isValid: isValid, messages: messages)
                    }
                }
                for await keyResult in group {
                    messages[keyResult.key] = keyResult.messages
                    if keyResult.isValid {
                        continue
                    }
                    errorFields.insert(keyResult.key)
                    isOveralValid = false
                }
                return (isOveralValid, FormError(errorFields: errorFields, messages: messages))
            }
            instantFormState.isValidating = false
            await syncFormState()
        } else if options.reValidateMode.contains(.onSubmit) {
            instantFormState.isValidating = true
            await syncFormState()
            (isOveralValid, errors) = await withTaskGroup(of: KeyValidationResult.self) { group -> (Bool, FormError<FieldName>) in
                var errorFields: Set<FieldName> = .init()
                var messages: [FieldName: [String]] = [:]
                var isOveralValid = true
                for (key, field) in fields where instantFormState.errors.errorFields.contains(key) {
                    group.addTask {
                        let (isValid, messages) = await field.computeMessages()
                        return KeyValidationResult(key: key, isValid: isValid, messages: messages)
                    }
                }
                for await keyResult in group {
                    messages[keyResult.key] = keyResult.messages
                    if !keyResult.isValid {
                        errorFields.insert(keyResult.key)
                        isOveralValid = false
                    }
                }
                return (isOveralValid, FormError(errorFields: errorFields, messages: messages))
            }
            instantFormState.isValidating = false
            await syncFormState()
        } else {
            await syncFormState()
            isOveralValid = instantFormState.isValid
            errors = instantFormState.errors
        }
        do {
            if isOveralValid {
                try await onValid(instantFormState.formValues, errors)
            } else {
                try await onInvalid?(instantFormState.formValues, errors)
            }
            instantFormState.errors = errors
            instantFormState.submitCount += 1
            instantFormState.submissionState = .submitted
            await syncFormState()
        } catch {
            instantFormState.submissionState = preservedSubmissionState
            throw error
        }
    }

    public func reset(defaultValues: FormValue<FieldName>, options: ResetOption = []) async {
        for (name, defaultValue) in defaultValues {
            if let defaultValue = Optional.some(defaultValue).flattened() {
                if !options.contains(.keepDefaultValues) {
                    instantFormState.defaultValues[name] = defaultValue
                }
            } else {
                assertionFailure("defaultValue must not be nil")
            }
            if !options.contains(.keepValues) {
                instantFormState.formValues[name] = defaultValue
            }
        }
        defaultValues.keys.forEach { name in
            if !options.contains(.keepDirty) {
                instantFormState.dirtyFields.remove(name)
            }
            if !options.contains(.keepErrors) {
                instantFormState.errors.removeMessagesOnly(name: name)
            }
            if !options.contains(.keepIsValid) {
                instantFormState.errors.removeValidityOnly(name: name)
            }
        }
        if !options.contains(.keepIsValid) {
            instantFormState.isValid = true
        }
        if !options.contains(.keepIsSubmitted) {
            instantFormState.submissionState = .notSubmit
            instantFormState.isSubmitSuccessful = false
        }
        if !options.contains(.keepSubmitCount) {
            instantFormState.submitCount = 0
        }
        
        if options.contains(.keepErrors) {
            await syncFormState()
        }
        if instantFormState.isValid {
            return await updateValid()
        }
        await syncFormState()
    }

    public func reset(name: FieldName, defaultValue: Any, options: SingleResetOption = []) async {
        guard let defaultValue = Optional.some(defaultValue).flattened() else {
            assertionFailure("defaultValue must not be nil")
            return
        }
        instantFormState.defaultValues[name] = defaultValue
        await reset(name: name, options: options)
    }

    public func reset(name: FieldName, options: SingleResetOption = []) async {
        instantFormState.formValues[name] = instantFormState.defaultValues[name]
        if !options.contains(.keepDirty) {
            instantFormState.dirtyFields.remove(name)
        }
        if options.contains(.keepError) {
            return await syncFormState()
        }
        instantFormState.errors.remove(name: name)
        if instantFormState.isValid {
            return await updateValid()
        }
        await syncFormState()
    }

    public func clearErrors(names: [FieldName]) async {
        names.forEach { name in
            instantFormState.errors.remove(name: name)
        }
        await syncFormState()
    }

    public func clearErrors(name: FieldName...) async {
        await clearErrors(names: name)
    }

    public func setValue(name: FieldName, value: Any, options: SetValueOption = []) async {
        instantFormState.formValues[name] = value
        if options.contains(.shouldDirty) || !areEqual(first: value, second: instantFormState.defaultValues[name]) {
            instantFormState.dirtyFields.insert(name)
        }
        if options.contains(.shouldValidate), let field = fields[name] {
            let (result, messages) = await field.computeMessages()
            instantFormState.errors.setMessages(name: name, messages: messages, isValid: result)
            if !result {
                instantFormState.isValid = false
            }
            return await syncFormState()
        }
        await syncFormState()
    }

    public func getFieldState(name: FieldName) -> FieldState {
        instantFormState.getFieldState(name: name)
    }

    public func getFieldState(name: FieldName) async -> FieldState {
        await formState.getFieldState(name: name)
    }

    public func trigger(names: [FieldName]) async -> Bool {
        instantFormState.isValidating = true
        await syncFormState()
        let (isValid, errors) = await withTaskGroup(of: KeyValidationResult.self) { group in
            var errors = instantFormState.errors
            for name in names {
                guard let field = fields[name] else {
                    continue
                }
                group.addTask {
                    let (isValid, messages) = await field.computeMessages()
                    return KeyValidationResult(key: name, isValid: isValid, messages: messages)
                }
            }
            var isValid = true
            for await keyResult in group {
                errors.setMessages(name: keyResult.key, messages: keyResult.messages, isValid: keyResult.isValid)
                if !keyResult.isValid {
                    isValid = false
                }
            }
            return (isValid, errors)
        }
        instantFormState.isValidating = false
        instantFormState.errors = errors
        await syncFormState()
        return isValid
    }

    public func trigger(name: FieldName...) async -> Bool {
        await trigger(names: name)
    }
}

extension FormControl {
    func updateValid() async {
        guard instantFormState.isValid else {
            return await syncFormState()
        }
        if let resolver = options.resolver {
            let isValid: Bool
            let result = await resolver(formState.formValues, options.context, .init(criteriaMode: options.criteriaMode, names: Array(formState.defaultValues.keys)))
            switch result {
            case .success:
                isValid = true
            case .failure(let error):
                isValid = false
                instantFormState.errors = error.errors
            }
            instantFormState.isValid = isValid
        } else {
            let (isValid, errors) = await withTaskGroup(of: KeyValidationResult.self) { group in
                var errors = instantFormState.errors
                for (key, field) in fields {
                    group.addTask {
                        let (isValid, messages) = await field.computeMessages()
                        return KeyValidationResult(key: key, isValid: isValid, messages: messages)
                    }
                }
                for await keyResult in group {
                    errors.setMessages(name: keyResult.key, messages: keyResult.messages, isValid: keyResult.isValid)
                    if keyResult.isValid {
                        continue
                    }
                    group.cancelAll()
                    return (false, errors)
                }
                return (true, errors)
            }
            instantFormState.errors = errors
            instantFormState.isValid = isValid
        }
        await syncFormState()
    }

    @MainActor
    func syncFormState() {
        if formState == instantFormState {
            return
        }
        formState = instantFormState
    }
}

private extension FormControl {
    class Field<Value>: FieldProtocol {
        let name: FieldName
        var options: RegisterOption<Value> {
            didSet {
                value = control.computeValueBinding(name: name, defaultValue: options.defaultValue)
            }
        }
        unowned var control: FormControl<FieldName>
        var value: Binding<Value>

        init(name: FieldName, options: RegisterOption<Value>, control: FormControl<FieldName>) {
            self.name = name
            self.options = options
            self.control = control
            self.value = control.computeValueBinding(name: name, defaultValue: options.defaultValue)
        }

        var anyValue: Any {
            value.wrappedValue
        }

        func computeValidationResult() async -> Bool {
            let validator = options.rules.eraseToAnyValidator()
            let result = await validator.validate(value.wrappedValue)
            return validator.isValid(result: result)
        }

        func computeMessages() async -> (Bool, [String]) {
            await options.rules.computeMessage(value: value.wrappedValue)
        }
    }

    func computeValueBinding<Value>(name: FieldName, defaultValue: Value) -> Binding<Value> {
        .init { [weak self] in
            self?.instantFormState.formValues[name] as? Value ?? defaultValue
        } set: { [weak self] value in
            self?.instantFormState.formValues[name] = value
            self?.instantFormState.dirtyFields.insert(name)
            guard let self = self, self.shouldReValidateOnChange(name: name) else {
                return
            }
            Task {
                await self.trigger(name: name)
            }
        }
    }

    func shouldReValidateOnChange(name: FieldName) -> Bool {
        if options.mode.contains(.onChange) {
            return true
        }
        guard instantFormState.errors.errorFields.contains(name) else {
            return false
        }
        return options.reValidateMode.contains(.onChange)
    }
}

private extension FormControl {
    struct KeyValidationResult {
        let key: FieldName
        let isValid: Bool
        let messages: [String]
    }
}
