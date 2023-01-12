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
    shouldFocusError: Bool,
    delayErrorInNanoseconds: UInt64 = 0,
    @_implicitSelfCapture onFocusedField: @escaping (FieldName) -> Void
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
            onFocusedField: onFocusedField
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
         onFocusedField: @escaping (FieldName) -> Void
    ) {
        self.mode = mode
        self.reValidateMode = reValidateMode
        self.resolver = resolver
        self.context = context
        self.shouldUnregister = shouldUnregister
        self.shouldFocusError = shouldFocusError
        self.delayErrorInNanoseconds = delayErrorInNanoseconds
        self.focusedFieldOption = .init(onFocusedField)
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
        let focusedFieldBinder: Any?
        let onFocusedField: ((FieldName) -> Void)?

        @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
        init(_ focusedFieldBinder: FocusState<FieldName?>.Binding) {
            self.focusedFieldBinder = focusedFieldBinder
            self.onFocusedField = nil
        }

        init(_ onFocusedField: @escaping (FieldName) -> Void) {
            self.focusedFieldBinder = nil
            self.onFocusedField = onFocusedField
        }

        @MainActor
        func triggerFocus(on field: FieldName) {
            if #available(macOS 12.0, iOS 15.0, tvOS 15.0, *), let focusedFieldBinder = focusedFieldBinder {
                (focusedFieldBinder as? FocusState<FieldName?>.Binding)?.wrappedValue = field
            } else {
                onFocusedField?(field)
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
