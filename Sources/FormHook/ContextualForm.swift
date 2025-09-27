//
//  ContextualForm.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import SwiftUI
import Hooks

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