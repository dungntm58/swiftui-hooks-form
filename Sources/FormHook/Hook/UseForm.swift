//
//  UseForm.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import Hooks
import SwiftUI

/// Use the `useForm` hook to manage forms with ease.
/// - Parameters:
///   - mode: The mode of the form. Defaults to `.onSubmit`.
///   - reValidateMode: The re-validation mode of the form. Defaults to `.onChange`.
///   - resolver: A custom resolver for the form. Defaults to `nil`.
///   - context: A custom context passed to the resolver when resolving fields values and errors. Defaults to `nil`.
///   - shouldUnregister: Whether or not the form should unregister inputs when unmounted. Defaults to `true`.
///   - shouldFocusError: Whether or not the form should focus on the first field with an error when submitting. Defaults to `true`.
///   - delayErrorInNanoseconds: Delay in nanoseconds before displaying any field error after submitting. Defaults to `0`.
///   - onFocusField: Callback called when a field is focused on by the user, passing a field name as parameter.
public func useForm<FieldName>(
    mode: Mode = .onSubmit,
    reValidateMode: ReValidateMode = .onChange,
    resolver: Resolver<FieldName>? = nil,
    context: Any? = nil,
    shouldUnregister: Bool = true,
    shouldFocusError: Bool = true,
    delayErrorInNanoseconds: UInt64 = 0,
    @_implicitSelfCapture onFocusField: @escaping (FieldName) -> Void
) -> FormControl<FieldName> where FieldName: Hashable {
    useForm(
        FormOption(
            mode: mode,
            reValidateMode: reValidateMode,
            resolver: resolver,
            context: context,
            shouldUnregister: shouldUnregister,
            shouldFocusError: shouldFocusError,
            delayErrorInNanoseconds: delayErrorInNanoseconds,
            onFocusField: onFocusField
        )
    )
}

/// Use the `useForm` hook to manage forms with ease.
/// - Parameters:
///   - mode: The mode of the form. Defaults to `.onSubmit`.
///   - reValidateMode: The re-validation mode of the form. Defaults to `.onChange`.
///   - resolver: A custom resolver for the form. Defaults to `nil`.
///   - context: A custom context for the form. Defaults to `nil`.
///   - shouldUnregister: Whether or not to unregister fields when they are removed from the form. Defaults to `true`.
///   - shouldFocusError: Whether or not to focus on errors when they occur. Defaults to `true`.
///   - delayErrorInNanoseconds: How long in nanoseconds to delay errors by. Defaults to 0.
///   - focusedStateBinder: A binding for focused state of a field in the form.  Defaults to nil. 
/// - Returns: A new instance of a `FormControl` with the given options.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public func useForm<FieldName>(
    mode: Mode = .onSubmit,
    reValidateMode: ReValidateMode = .onChange,
    resolver: Resolver<FieldName>? = nil,
    context: Any? = nil,
    shouldUnregister: Bool = true,
    shouldFocusError: Bool = true,
    delayErrorInNanoseconds: UInt64 = 0,
    focusedStateBinder: FocusState<FieldName?>.Binding
) -> FormControl<FieldName> where FieldName: Hashable {
    useForm(
        FormOption(
            mode: mode,
            reValidateMode: reValidateMode,
            resolver: resolver,
            context: context,
            shouldUnregister: shouldUnregister,
            shouldFocusError: shouldFocusError,
            delayErrorInNanoseconds: delayErrorInNanoseconds,
            focusedStateBinder: focusedStateBinder
        )
    )
}

/// Use the `useForm` hook to manage forms with ease.
/// - Parameters:
///   - options: The `FormOption`s to be used in the form.
/// - Returns: A `FormControl` object with the given `FormOption`s.
public func useForm<FieldName>(_ options: FormOption<FieldName>) -> FormControl<FieldName> where FieldName: Hashable {
    let state = useState(FormState<FieldName>())
    let formRef = useRef(FormControl<FieldName>(options: options, formState: state))
    formRef.current.options = options
    return formRef.current
}

/// A generic struct that allows for the configuration of a form.
public struct FormOption<FieldName> where FieldName: Hashable {
    var mode: Mode
    var reValidateMode: ReValidateMode
    var resolver: Resolver<FieldName>?
    var context: Any?
    var shouldUnregister: Bool
    var shouldFocusError: Bool
    var delayErrorInNanoseconds: UInt64
    let focusedFieldOption: FocusedFieldOption

    /// Initialize a `FormOption`
    /// - Parameters:
    ///   - mode: The mode of the form.
    ///   - reValidateMode: The revalidate mode of the form.
    ///   - resolver: A custom resolver to be used by the form.
    ///   - context: Any additional context needed by the form.
    ///   - shouldUnregister: Whether or not to unregister fields when they are removed from the form.
    ///   - shouldFocusError: Whether or not to focus on an error when it occurs. 
    ///   - delayErrorInNanoseconds: The delay in nanoseconds before an error is shown. 
    ///   - onFocusField: A closure that will be called when a field is focused on.
    public init(mode: Mode,
         reValidateMode: ReValidateMode,
         @_implicitSelfCapture resolver: Resolver<FieldName>?,
         context: Any?,
         shouldUnregister: Bool,
         shouldFocusError: Bool,
         delayErrorInNanoseconds: UInt64,
         onFocusField: @escaping (FieldName) -> Void
    ) {
        self.mode = mode
        self.reValidateMode = reValidateMode
        self.resolver = resolver
        self.context = context
        self.shouldUnregister = shouldUnregister
        self.shouldFocusError = shouldFocusError
        self.delayErrorInNanoseconds = delayErrorInNanoseconds
        self.focusedFieldOption = .init(onFocusField)
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public init(mode: Mode,
         reValidateMode: ReValidateMode,
         @_implicitSelfCapture resolver: Resolver<FieldName>?,
         context: Any?,
         shouldUnregister: Bool,
         shouldFocusError: Bool,
         delayErrorInNanoseconds: UInt64,
         focusedStateBinder: FocusState<FieldName?>.Binding
    ) {
        self.mode = mode
        self.reValidateMode = reValidateMode
        self.resolver = resolver
        self.context = context
        self.shouldUnregister = shouldUnregister
        self.shouldFocusError = shouldFocusError
        self.delayErrorInNanoseconds = delayErrorInNanoseconds
        self.focusedFieldOption = .init(focusedStateBinder)
    }

    struct FocusedFieldOption {
        private let anyFocusedFieldBinder: Any?
        private let onFocusField: ((FieldName) -> Void)?

        var hasFocusedFieldBinder: Bool {
            anyFocusedFieldBinder != nil
        }

        var focusedFieldBindingValue: FieldName? {
            if #available(macOS 12.0, iOS 15.0, tvOS 15.0, *) {
                return focusedFieldBinder?.wrappedValue
            }
            return nil
        }

        @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
        var focusedFieldBinder: FocusState<FieldName?>.Binding? {
            anyFocusedFieldBinder as? FocusState<FieldName?>.Binding
        }

        @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
        init(_ focusedFieldBinder: FocusState<FieldName?>.Binding) {
            self.anyFocusedFieldBinder = focusedFieldBinder
            self.onFocusField = nil
        }

        init(_ onFocusField: @escaping (FieldName) -> Void) {
            self.anyFocusedFieldBinder = nil
            self.onFocusField = onFocusField
        }

        @MainActor
        func triggerFocus(on field: FieldName) {
            if let onFocusField {
                return onFocusField(field)
            }
            if #available(macOS 12.0, iOS 15.0, tvOS 15.0, *) {
                focusedFieldBinder?.wrappedValue = field
            }
        }
    }
}

/// A set of options that can be used to configure a behavior.
///
/// The `Mode` type is an `OptionSet` that defines two options, `onSubmit` and `onChange`. It also provides a static property, `all`, which is the union of both options.
public struct Mode: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Indicates when a submission should occur.
    public static let onSubmit = Mode(rawValue: 1 << 0)

    /// Indicates when a change should occur. 
    public static let onChange = Mode(rawValue: 1 << 1)

    /// A combination of both options, `onSubmit` and `onChange`. 
    public static let all: Mode = [onChange, onSubmit]
}

public typealias ReValidateMode = Mode

/// A typealias for a function that resolves a form.
/// - Parameters:
///   - values: The values of the form.
///   - context: Any additional context needed to resolve the form.
///   - fieldNames: An array of field names to be resolved.
/// - Returns: A `Result` containing either the resolved values or an error. 
public typealias Resolver<FieldName> = (
    _ values: ResolverValue<FieldName>,
    _ context: Any?,
    _ fieldNames: [FieldName]
) async -> Result<ResolverValue<FieldName>, ResolverError<FieldName>> where FieldName: Hashable

public typealias ResolverValue = FormValue
public typealias ResolverError = FormError
