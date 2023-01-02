//
//  UseForm.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import Hooks

public func useForm<FieldName>(
    mode: Mode = .onSubmit,
    reValidateMode: ReValidateMode = .onChange,
    resolver: Resolver<FieldName>? = nil,
    context: Any? = nil,
    shouldUnregister: Bool = true,
    delayError: Bool = false
) -> FormControl<FieldName> where FieldName: Hashable {
    useForm(
        FormOption(
            mode: mode,
            reValidateMode: reValidateMode,
            resolver: resolver,
            context: context,
            shouldUnregister: shouldUnregister,
            delayError: delayError
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
    let resolver: Resolver<FieldName>?
    let context: Any?
    let shouldUnregister: Bool
    let delayError: Bool

    init(mode: Mode,
         reValidateMode: ReValidateMode,
         resolver: Resolver<FieldName>?,
         context: Any?,
         shouldUnregister: Bool,
         delayError: Bool
    ) {
        self.mode = mode
        self.reValidateMode = reValidateMode
        self.resolver = resolver
        self.context = context
        self.shouldUnregister = shouldUnregister
        self.delayError = delayError
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
