//
//  UseForm.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import SwiftUI
import Hooks

/// A control that holds form information
public class FormControl<FieldName> where FieldName: Hashable {
    var options: FormOption<FieldName>

    private var currentErrorNotifyTask: Task<Void, Error>?
    private var fields: [FieldName: FieldProtocol]

    private var _currentFocusedField: FieldName?

    @MainActor
    private var currentFocusedField: FieldName? {
        get {
            _currentFocusedField ?? options.focusedFieldOption.focusedFieldBindingValue
        }
        set {
            if let newValue {
                options.focusedFieldOption.triggerFocus(on: newValue)
            }
            if options.focusedFieldOption.hasFocusedFieldBinder {
                return
            }
            _currentFocusedField = newValue
        }
    }

    var instantFormState: FormState<FieldName>
    @MainActor @Binding
    private(set) public var formState: FormState<FieldName>

    init(options: FormOption<FieldName>, formState: Binding<FormState<FieldName>>) {
        self.options = options
        self.fields = [:]
        self._formState = formState
        self.instantFormState = formState.wrappedValue
    }

    /// Register an input or select element and apply validation rules to SwiftUI Hook Form
    /// - Parameters: 
    ///     - name: The name of the field.
    ///     - options: The options for the field, such as its default value and field ordinal.
    /// - Returns: A `FieldRegistration` object containing the value of the field.
    public func register<Value>(name: FieldName, options: RegisterOption<Value>) -> FieldRegistration<Value> {
        self.instantFormState.defaultValues[name] = options.defaultValue
        let field: Field<Value>
        if let f = fields[name] as? Field<Value> {
            field = f
            if !areEqual(first: options.defaultValue, second: field.options.defaultValue) && !instantFormState.dirtyFields.contains(name) {
                instantFormState.formValues[name] = options.defaultValue
            }
            field.options = options
            if let fieldOrdinal = options.fieldOrdinal {
                field.fieldOrdinal = fieldOrdinal
            }
        } else {
            field = Field(fieldOrdinal: options.fieldOrdinal ?? fields.count, name: name, options: options, control: self)
            fields[name] = field
            instantFormState.formValues[name] = options.defaultValue
        }
        return field.value
    }

    deinit {
        currentErrorNotifyTask?.cancel()
        currentErrorNotifyTask = nil
    }

    /// Unregister a single input or an array of inputs
    /// - Parameters:
    ///   - names: The name(s) of the input(s) to unregister.
    ///   - options: Options for unregistering the input(s).
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

    /// Unregister a single input or an array of inputs
    /// - Parameters:
    ///   - name: The name(s) of the input(s) to unregister.
    ///   - options: Options for unregistering the field name.
    public func unregister(name: FieldName..., options: UnregisterOption = []) async {
        await unregister(names: name, options: options)
    }

    /// Handles the submission of a form.
    /// - Parameters:
    ///     - onValid: A closure that is called when the form is valid. It takes two arguments: the form value and any errors that were encountered.
    ///     - onInvalid: An optional closure that is called when the form is invalid. It takes two arguments: the form value and any errors that were encountered. If not provided, an error will be thrown instead.
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
                    instantFormState.formValues.unioned(formValues)
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
                    instantFormState.formValues.unioned(formValues)
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
            }
            await postHandleSubmit(isOveralValid: isOveralValid, errors: errors, isSubmitSuccessful: errors.errorFields.isEmpty)
        } catch {
            await postHandleSubmit(isOveralValid: isOveralValid, errors: errors, isSubmitSuccessful: false)
            throw error
        }
    }

    /// Reset the entire form state, fields reference, and subscriptions. There are optional arguments and will allow partial form state reset.
    /// - Parameters: 
    ///   - defaultValues: A `FormValue` containing the default values for each field.
    ///   - options: An optional array of `ResetOption`s which will allow partial form state reset.
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

    /// Resets an individual field state.
    /// - Parameters:
    ///   - name: The name of the field to reset.
    ///   - defaultValue: The default value of the field. Must not be nil.
    ///   - options: Options for resetting the field.
    public func reset(name: FieldName, defaultValue: Any, options: SingleResetOption = []) async {
        guard let defaultValue = Optional.some(defaultValue).flattened() else {
            assertionFailure("defaultValue must not be nil")
            return
        }
        instantFormState.defaultValues[name] = defaultValue
        await reset(name: name, options: options)
    }

    /// Resets an individual field state.
    /// - Parameters:
    ///   - name: The name of the field to reset.
    ///   - options: Options for resetting the field.
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

    /// This function can manually clear errors in the form.
    /// - Parameters:
    ///   - names: An array of `FieldName`s to remove errors from.
    public func clearErrors(names: [FieldName]) async {
        names.forEach { name in
            instantFormState.errors.remove(name: name)
        }
        await syncFormState()
    }

    /// This function can manually clear errors in the form.
    /// - Parameters:
    ///   - name: A variadic list of `FieldName`s to remove errors from.
    public func clearErrors(name: FieldName...) async {
        await clearErrors(names: name)
    }

    /// Sets the value of a registered field and updates the form state.
    /// - Parameters:
    ///   - name: The name of the field to set.
    ///   - value: The value to set for the field.
    ///   - options: An array of `SetValueOption`s that determine how the form state should be updated.
    /// - Returns: An asynchronous task that returns when the form state has been updated.
    public func setValue(name: FieldName, value: Any, options: SetValueOption = []) async {
        instantFormState.formValues[name] = value
        if options.contains(.shouldDirty) || !areEqual(first: value, second: instantFormState.defaultValues[name]) {
            instantFormState.dirtyFields.insert(name)
        }
        guard options.contains(.shouldValidate) else {
            return await syncFormState()
        }
        await trigger(name: name)
    }

    /// Return individual field state
    /// - Parameter name: The name of the field to get the state of. 
    /// - Returns: A `FieldState` object containing information about a single field in a form state object.
    public func getFieldState(name: FieldName) -> FieldState {
        instantFormState.getFieldState(name: name)
    }

    /// Return individual field state asynchronously
    /// - Parameter name: The name of the field to get the state of. 
    /// - Returns: A `FieldState` object containing information about a single field in a form state object.
    public func getFieldState(name: FieldName) async -> FieldState {
        await formState.getFieldState(name: name)
    }

    /// Manually triggers form or input validation. This method is also useful when you have dependant validation (input validation depends on another input's value).
    ///  - Parameters: 
    ///     - names: An array of `FieldName`s to be validated. 
    ///     - shouldFocus: A boolean indicating whether the field should be focused after validation. Defaults to `false`. 
    ///  - Returns: A boolean indicating whether all validations passed successfully or not.
    @discardableResult
    public func trigger(names: [FieldName], shouldFocus: Bool = false) async -> Bool {
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
                instantFormState.formValues.unioned(formValues)
            case .failure(let e):
                isValid = false
                errors = instantFormState.errors.union(e)
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
            instantFormState.isValid = isValid
        }
        instantFormState.isValidating = false

        currentErrorNotifyTask?.cancel()
        if options.delayErrorInNanoseconds == 0 || isValid {
            currentErrorNotifyTask = nil
            instantFormState.errors = errors
            await syncFormState()
            if shouldFocus {
                await focusFieldAfterTrigger(names: validationNames, errorFields: errors.errorFields)
            }
        } else {
            await syncFormState()
            let delayErrorInNanoseconds = options.delayErrorInNanoseconds
            currentErrorNotifyTask = Task { [weak self] in
                try await Task.sleep(nanoseconds: delayErrorInNanoseconds)
                self?.instantFormState.errors = errors
                await self?.syncFormState()
                if shouldFocus {
                    await self?.focusFieldAfterTrigger(names: validationNames, errorFields: errors.errorFields)
                }
            }
        }
        return isValid
    }

    /// Manually triggers form or input validation. This method is also useful when you have dependant validation (input validation depends on another input's value).
    ///  - Parameters: 
    ///     - names: variadic list of `FieldName`s to be validated. 
    ///     - shouldFocus: A boolean indicating whether the field should be focused after validation. Defaults to `false`. 
    ///  - Returns: A boolean indicating whether all validations passed successfully or not.
    @discardableResult
    public func trigger(name: FieldName..., shouldFocus: Bool = false) async -> Bool {
        await trigger(names: name, shouldFocus: shouldFocus)
    }
}

extension FormControl {
    func updateValid() async {
        guard instantFormState.isValid else {
            return
        }
        if let resolver = options.resolver {
            let result = await resolver(instantFormState.formValues, options.context, Array(fields.keys))
            switch result {
            case .success(let formValues):
                instantFormState.isValid = true
                instantFormState.formValues.unioned(formValues)
                await syncFormState()
            case .failure(let e):
                await onResultPostUpdateValid(e, isValid: false)
            }
            return
        }
        let (isValid, errors) = await withTaskGroup(of: KeyValidationResult.self) { group in
            var errors = instantFormState.errors
            for (key, field) in fields {
                _ = group.addTaskUnlessCancelled {
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
        await onResultPostUpdateValid(errors, isValid: isValid)
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
        var fieldOrdinal: Int
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

        init(fieldOrdinal: Int, name: FieldName, options: RegisterOption<Value>, control: FormControl<FieldName>) {
            self.fieldOrdinal = fieldOrdinal
            self.name = name
            self.options = options
            self.control = control
            self.value = control.computeValueBinding(name: name, defaultValue: options.defaultValue)
        }

        var shouldUnregister: Bool {
            options.shouldUnregister
        }

        func computeMessages() async -> (Bool, [String]) {
            await options.rules.computeMessage(value: value.wrappedValue)
        }
    }

    func computeValueBinding<Value>(name: FieldName, defaultValue: Value) -> Binding<Value> {
        .init { [weak self] in
            self?.instantFormState.formValues[name] as? Value ?? defaultValue
        } set: { [weak self] value in
            guard let self else {
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
                await self.trigger(name: name, shouldFocus: true)
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

    func postHandleSubmit(isOveralValid: Bool, errors: FormError<FieldName>, isSubmitSuccessful: Bool) async {
        instantFormState.submissionState = .submitted
        instantFormState.isSubmitSuccessful = isSubmitSuccessful
        instantFormState.submitCount += 1
        await onResultPostUpdateValid(errors, isValid: isOveralValid)
    }

    @MainActor
    func focusFieldAfterTrigger(names: [FieldName], errorFields: Set<FieldName>) {
        let focusField: FieldName?
        if names.count == 1  {
            focusField = names[0]
            if currentFocusedField != nil && currentFocusedField != focusField {
                return
            }
        } else {
            focusField = names.first(where: errorFields.contains)
        }
        guard let focusField else {
            return
        }
        currentFocusedField = focusField
    }

    func onResultPostUpdateValid(_ errors: FormError<FieldName>, isValid: Bool) async {
        instantFormState.isValid = isValid
        currentErrorNotifyTask?.cancel()
        if options.delayErrorInNanoseconds == 0 || isValid {
            currentErrorNotifyTask = nil
            instantFormState.errors = errors
            await syncFormState()
            return await focusError(with: errors)
        }
        await syncFormState()
        let delayErrorInNanoseconds = options.delayErrorInNanoseconds
        currentErrorNotifyTask = Task { [weak self] in
            try await Task.sleep(nanoseconds: delayErrorInNanoseconds)
            self?.instantFormState.errors = errors
            await self?.syncFormState()
            await self?.focusError(with: errors)
        }
    }

    @MainActor
    func focusError(with errors: FormError<FieldName>) {
        guard options.shouldFocusError else {
            return
        }
        let fields = fields.sorted { $0.value.fieldOrdinal < $1.value.fieldOrdinal }
        let firstErrorField = fields.first(where: { errors.errorFields.contains($0.key) })?.key
        guard let firstErrorField else {
            return
        }
        currentFocusedField = firstErrorField
    }
}

private extension FormControl {
    struct KeyValidationResult {
        let key: FieldName
        let isValid: Bool
        let messages: [String]
    }
}

/// A convenient view that wraps a call of `useForm`.
public struct ContextualForm<Content, FieldName>: View where Content: View, FieldName: Hashable {
    let formOptions: FormOption<FieldName>
    let contentBuilder: (FormControl<FieldName>) -> Content

    /// Initialize a `ContextualForm`
    /// - Parameters:
    ///   - mode: The mode in which the form will be validated. Defaults to `.onSubmit`.
    ///   - reValidateMode: The mode in which the form will be re-validated. Defaults to `.onChange`.
    ///   - resolver: A resolver used to resolve validation rules for fields. Defaults to `nil`.
    ///   - context: An optional context that can be used when resolving validation rules for fields. Defaults to `nil`.
    ///   - shouldUnregister: A boolean value that indicates whether the form should unregister its fields when it is deallocated. Defaults to `true`.
    ///   - shouldFocusError: A boolean value that indicates whether the form should focus on an error field when it is invalidated. Defaults to `true`.
    ///   - delayErrorInNanoseconds: The amount of time (in nanoseconds) that the form will wait before focusing on an error field when it is invalidated. Defaults to 0 nanoseconds (no delay).
    ///   - onFocusField: An action performed when a field is focused on by the user or programmatically by the form.
    ///   - contentBuilder: A closure used for building content for the contextual form view, using a FormControl<FieldName> instance as a parameter.
    public init(
        mode: Mode = .onSubmit,
        reValidateMode: ReValidateMode = .onChange,
        resolver: Resolver<FieldName>? = nil,
        context: Any? = nil,
        shouldUnregister: Bool = true,
        shouldFocusError: Bool = true,
        delayErrorInNanoseconds: UInt64 = 0,
        @_implicitSelfCapture onFocusField: @escaping (FieldName) -> Void,
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
            onFocusField: onFocusField
        )
        self.contentBuilder = content
    }

    /// Initialize a `ContextualForm`
    /// - Parameters:
    ///   - mode: The mode in which the form will be validated. Defaults to `.onSubmit`.
    ///   - reValidateMode: The mode in which the form will be re-validated. Defaults to `.onChange`.
    ///   - resolver: A resolver used to resolve validation rules for fields. Defaults to `nil`.
    ///   - context: An optional context that can be used when resolving validation rules for fields. Defaults to `nil`.
    ///   - shouldUnregister: A boolean value that indicates whether the form should unregister its fields when it is deallocated. Defaults to `true`.
    ///   - shouldFocusError: A boolean value that indicates whether the form should focus on an error field when it is invalidated. Defaults to `true`.
    ///   - delayErrorInNanoseconds: The amount of time (in nanoseconds) that the form will wait before focusing on an error field when it is invalidated. Defaults to 0 nanoseconds (no delay).
    ///   - focusedFieldBinder: A binding used to bind a FocusState<FieldName?> instance, which holds information about which field is currently focused on by the user or programmatically by the form. 
    ///   - contentBuilder: A closure used for building content for the contextual form view, using a FormControl<FieldName> instance as a parameter.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public init(
        mode: Mode = .onSubmit,
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
