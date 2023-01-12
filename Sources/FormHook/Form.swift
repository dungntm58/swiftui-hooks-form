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
    var currentErrorNotifyTask: Task<Void, Error>?

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
        self.instantFormState.defaultValues[name] = options.defaultValue
        let field: Field<Value>
        if let f = fields[name] as? Field<Value> {
            field = f
            if !areEqual(first: options.defaultValue, second: field.options.defaultValue) && !instantFormState.dirtyFields.contains(name) {
                instantFormState.formValues[name] = options.defaultValue
            }
            field.options = options
        } else {
            field = Field(index: fields.count, name: name, options: options, control: self)
            fields[name] = field
            instantFormState.formValues[name] = options.defaultValue
        }
        return field.value
    }

    deinit {
        currentErrorNotifyTask?.cancel()
        currentErrorNotifyTask = nil
    }

    public func unregister(names: [FieldName], options: UnregisterOption = []) async {
        if self.options.shouldUnregister {
            names.forEach { fields[$0] = nil }
        }
        names.forEach {
            if fields[$0]?.shouldUnregister ?? false {
                fields[$0] = nil
            }
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
        if !options.contains(.keepDefaultValue) {
            names.forEach { instantFormState.defaultValues[$0] = nil }
        }
        if options.contains(.keepIsValid) {
            return await updateValid()
        }
        names.forEach { instantFormState.errors.removeValidityOnly(name: $0) }
    }

    public func unregister(name: FieldName..., options: UnregisterOption = []) async {
        await unregister(names: name, options: options)
    }

    public func handleSubmit(
        @_implicitSelfCapture onValid: @escaping (FormValue<FieldName>, FormError<FieldName>) async throws -> Void,
        @_implicitSelfCapture onInvalid: ((FormValue<FieldName>, FormError<FieldName>) async throws -> Void)? = nil
    ) async throws {
        instantFormState.submissionState = .submitting
        let errors: FormError<FieldName>
        var isOveralValid: Bool
        if options.mode.contains(.onSubmit) {
            instantFormState.isValidating = true
            await syncFormState()
            if let resolver = options.resolver {
                let result = await resolver(
                    instantFormState.formValues,
                    options.context,
                    Array(fields.keys)
                )
                switch result {
                case .success(let formValues):
                    isOveralValid = true
                    errors = .init()
                    instantFormState.formValues.update(other: formValues)
                case .failure(let e):
                    isOveralValid = false
                    errors = e
                }
            } else {
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
            }
            instantFormState.isValidating = false
            await syncFormState()
        } else if options.reValidateMode.contains(.onSubmit) {
            instantFormState.isValidating = true
            await syncFormState()
            if let resolver = options.resolver {
                let names = fields.keys.filter(instantFormState.errors.errorFields.contains)
                let result = await resolver(instantFormState.formValues, options.context, names)
                switch result {
                case .success(let formValues):
                    isOveralValid = true
                    errors = .init()
                    instantFormState.formValues.update(other: formValues)
                case .failure(let e):
                    isOveralValid = false
                    errors = e
                }
            } else {
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
            } else if let onInvalid {
                try await onInvalid(instantFormState.formValues, errors)
                await focusError(with: errors)
            }
            await postHandleSubmit(isOveralValid: isOveralValid, errors: errors, isSubmitSuccessful: errors.errorFields.isEmpty)
        } catch {
            await postHandleSubmit(isOveralValid: isOveralValid, errors: errors, isSubmitSuccessful: false)
            throw error
        }
    }

    private func focusError(with errors: FormError<FieldName>) async {
        guard options.shouldFocusError else {
            return
        }
        let fields = fields
            .sorted { $0.value.index < $1.value.index }
        guard let firstErrorField = fields.first(where: { errors.errorFields.contains($0.key) })?.key else {
            return
        }
        await options.focusedFieldOption.triggerFocus(on: firstErrorField)
    }

    private func postHandleSubmit(isOveralValid: Bool, errors: FormError<FieldName>, isSubmitSuccessful: Bool) async {
        instantFormState.isValid = isOveralValid
        instantFormState.submissionState = .submitted
        instantFormState.isSubmitSuccessful = isSubmitSuccessful
        currentErrorNotifyTask?.cancel()
        instantFormState.submitCount += 1
        if options.delayErrorInNanoseconds == 0 || isOveralValid {
            currentErrorNotifyTask = nil
            instantFormState.errors = errors
            await syncFormState()
        } else {
            await syncFormState()
            let delayErrorInNanoseconds = options.delayErrorInNanoseconds
            currentErrorNotifyTask = Task { [weak self] in
                try await Task.sleep(nanoseconds: delayErrorInNanoseconds)
                self?.instantFormState.errors = errors
                await self?.syncFormState()
            }
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
        if !options.contains(.keepErrors) {
            await updateValid()
        }
        return await syncFormState()
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
        if !options.contains(.keepError) {
            instantFormState.errors.remove(name: name)
            await updateValid()
        }
        return await syncFormState()
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
        guard options.contains(.shouldValidate) else {
            return await syncFormState()
        }
        if let resolver = self.options.resolver {
            let result = await resolver(instantFormState.formValues, self.options.context, [name])
            switch result {
            case .success:
                break
            case .failure(let e):
                instantFormState.errors = instantFormState.errors.rewrite(from: e)
                instantFormState.isValid = false
            }
        } else if let field = fields[name] {
            let (isValid, messages) = await field.computeMessages()
            instantFormState.errors.setMessages(name: name, messages: messages, isValid: isValid)
            if !isValid {
                instantFormState.isValid = false
            }
        }
        return await syncFormState()
    }

    public func getFieldState(name: FieldName) -> FieldState {
        instantFormState.getFieldState(name: name)
    }

    public func getFieldState(name: FieldName) async -> FieldState {
        await formState.getFieldState(name: name)
    }

    @discardableResult
    public func trigger(names: [FieldName]) async -> Bool {
        let validationNames = names.isEmpty ? fields.map { $0.key } : names
        instantFormState.isValidating = true
        await syncFormState()
        let isValid: Bool
        let errors: FormError<FieldName>
        if let resolver = options.resolver {
            let result = await resolver(instantFormState.formValues, options.context, validationNames)
            switch result {
            case .success(let formValues):
                isValid = true
                errors = instantFormState.errors
                instantFormState.formValues.update(other: formValues)
            case .failure(let e):
                isValid = false
                errors = instantFormState.errors.rewrite(from: e)
            }
        } else {
            (isValid, errors) = await withTaskGroup(of: KeyValidationResult.self) { group in
                var errors = instantFormState.errors
                for name in validationNames {
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
        }
        if !isValid {
            instantFormState.isValid = false
        }
        instantFormState.isValidating = false
        currentErrorNotifyTask?.cancel()
        if options.delayErrorInNanoseconds == 0 {
            instantFormState.errors = errors
            await syncFormState()
        } else {
            await syncFormState()
            let delayErrorInNanoseconds = options.delayErrorInNanoseconds
            currentErrorNotifyTask = Task { [weak self] in
                try await Task.sleep(nanoseconds: delayErrorInNanoseconds)
                self?.instantFormState.errors = errors
                await self?.syncFormState()
            }
        }
        return isValid
    }

    @discardableResult
    public func trigger(name: FieldName...) async -> Bool {
        await trigger(names: name)
    }
}

extension FormControl {
    func updateValid() async {
        guard instantFormState.isValid else {
            return
        }
        if let resolver = options.resolver {
            let isValid: Bool
            let result = await resolver(instantFormState.formValues, options.context, Array(fields.keys))
            switch result {
            case .success(let formValues):
                isValid = true
                instantFormState.formValues.update(other: formValues)
            case .failure(let e):
                isValid = false
                currentErrorNotifyTask?.cancel()
                if options.delayErrorInNanoseconds == 0 || isValid {
                    currentErrorNotifyTask = nil
                    instantFormState.errors = e
                } else {
                    let delayErrorInNanoseconds = options.delayErrorInNanoseconds
                    currentErrorNotifyTask = Task { [weak self] in
                        try await Task.sleep(nanoseconds: delayErrorInNanoseconds)
                        self?.instantFormState.errors = e
                        await self?.syncFormState()
                    }
                }
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
            currentErrorNotifyTask?.cancel()
            if options.delayErrorInNanoseconds == 0 || isValid {
                currentErrorNotifyTask = nil
                instantFormState.errors = errors
            } else {
                let delayErrorInNanoseconds = options.delayErrorInNanoseconds
                currentErrorNotifyTask = Task { [weak self] in
                    try await Task.sleep(nanoseconds: delayErrorInNanoseconds)
                    self?.instantFormState.errors = errors
                    await self?.syncFormState()
                }
            }
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
        let index: Int
        let name: FieldName
        var options: RegisterOption<Value> {
            didSet {
                if areEqual(first: oldValue.defaultValue, second: options.defaultValue) {
                    return
                }
                value = control.computeValueBinding(name: name, defaultValue: options.defaultValue)
            }
        }
        unowned var control: FormControl<FieldName>
        var value: Binding<Value>

        init(index: Int, name: FieldName, options: RegisterOption<Value>, control: FormControl<FieldName>) {
            self.index = index
            self.name = name
            self.options = options
            self.control = control
            self.value = control.computeValueBinding(name: name, defaultValue: options.defaultValue)
        }

        var shouldUnregister: Bool {
            options.shouldUnregister
        }

        func computeResult() async -> Bool {
            await options.rules.isValid(value.wrappedValue)
        }

        func computeMessages() async -> (Bool, [String]) {
            await options.rules.computeMessage(value: value.wrappedValue)
        }
    }

    func computeValueBinding<Value>(name: FieldName, defaultValue: Value) -> Binding<Value> {
        .init { [weak self] in
            self?.instantFormState.formValues[name] as? Value ?? defaultValue
        } set: { [weak self] value in
            guard let self = self else {
                return
            }
            self.instantFormState.formValues[name] = value
            if !self.instantFormState.dirtyFields.contains(name) && !areEqual(first: self.instantFormState.defaultValues[name], second: value) {
                self.instantFormState.dirtyFields.insert(name)
            }
            guard self.shouldReValidateOnChange(name: name) else {
                return
            }
            Task {
                await self.trigger(name: name)
                await self.options.focusedFieldOption.triggerFocus(on: name)
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

public struct ContextualForm<Content, FieldName>: View where Content: View, FieldName: Hashable {
    let formOptions: FormOption<FieldName>
    let contentBuilder: (FormControl<FieldName>) -> Content

    public init(mode: Mode = .onSubmit,
                reValidateMode: ReValidateMode = .onChange,
                resolver: Resolver<FieldName>? = nil,
                context: Any? = nil,
                shouldUnregister: Bool = true,
                shouldFocusError: Bool = true,
                delayErrorInNanoseconds: UInt64 = 0,
                @_implicitSelfCapture onFocusedField: @escaping (FieldName) -> Void,
                @ViewBuilder content: @escaping (FormControl<FieldName>) -> Content
    ) {
        self.formOptions = .init(
            mode: mode,
            reValidateMode: reValidateMode,
            resolver: resolver,
            context: context,
            shouldUnregister: shouldUnregister,
            shouldFocusError: shouldFocusError,
            delayErrorInNanoseconds: delayErrorInNanoseconds,
            onFocusedField: onFocusedField
        )
        self.contentBuilder = content
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public init(mode: Mode = .onSubmit,
                reValidateMode: ReValidateMode = .onChange,
                resolver: Resolver<FieldName>? = nil,
                context: Any? = nil,
                shouldUnregister: Bool = true,
                shouldFocusError: Bool = true,
                delayErrorInNanoseconds: UInt64 = 0,
                focusedFieldBinder: FocusState<FieldName?>.Binding,
                @ViewBuilder content: @escaping (FormControl<FieldName>) -> Content
    ) {
        self.formOptions = .init(
            mode: mode,
            reValidateMode: reValidateMode,
            resolver: resolver,
            context: context,
            shouldUnregister: shouldUnregister,
            shouldFocusError: shouldFocusError,
            delayErrorInNanoseconds: delayErrorInNanoseconds,
            focusedStateBinder: focusedFieldBinder
        )
        self.contentBuilder = content
    }

    public var body: some View {
        HookScope {
            let form = useForm(formOptions)
            Context.Provider(value: form) {
                contentBuilder(form)
            }
        }
    }
}
