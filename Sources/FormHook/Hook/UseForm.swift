//
//  UseForm.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import Hooks
import SwiftUI

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

public func useForm<FieldName>(_ options: FormOption<FieldName>) -> FormControl<FieldName> where FieldName: Hashable {
    let state = useState(FormState<FieldName>())
    let formRef = useRef(FormControl<FieldName>(options: options, formState: state))
    formRef.current.options = options
    return formRef.current
}

public struct FormOption<FieldName> where FieldName: Hashable {
    var mode: Mode
    var reValidateMode: ReValidateMode
    var resolver: Resolver<FieldName>?
    var context: Any?
    var shouldUnregister: Bool
    var shouldFocusError: Bool
    var delayErrorInNanoseconds: UInt64
    let focusedFieldOption: FocusedFieldOption

    init(mode: Mode,
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
    init(mode: Mode,
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

public struct Mode: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let onSubmit = Mode(rawValue: 1 << 0)
    public static let onChange = Mode(rawValue: 1 << 1)
    public static let all: Mode = [onChange, onSubmit]
}

public typealias ReValidateMode = Mode

public typealias Resolver<FieldName> = (
    _ values: ResolverValue<FieldName>,
    _ context: Any?,
    _ fieldNames: [FieldName]
) async -> Result<ResolverValue<FieldName>, ResolverError<FieldName>> where FieldName: Hashable

public typealias ResolverValue = FormValue
public typealias ResolverError = FormError
