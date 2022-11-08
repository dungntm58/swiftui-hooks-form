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
    criteriaMode: CriteriaMode = .all,
    delayError: Bool = false
) -> FormControl<FieldName> where FieldName: Hashable {
    useForm(
        FormOption(
            mode: mode,
            reValidateMode: reValidateMode,
            resolver: resolver,
            context: context,
            shouldUnregister: shouldUnregister,
            criteriaMode: criteriaMode,
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

public struct FormOption<FieldName>: Equatable where FieldName: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.mode == rhs.mode
        && lhs.reValidateMode == rhs.reValidateMode
        && areEqual(first: lhs.context, second: rhs.context)
        && lhs.shouldUnregister == rhs.shouldUnregister
        && lhs.criteriaMode == rhs.criteriaMode
        && lhs.delayError == rhs.delayError
    }

    let mode: Mode
    let reValidateMode: ReValidateMode
    let resolver: Resolver<FieldName>?
    let context: Any?
    let shouldUnregister: Bool
    let criteriaMode: CriteriaMode
    let delayError: Bool

    init(mode: Mode,
         reValidateMode: ReValidateMode,
         resolver: Resolver<FieldName>?,
         context: Any?,
         shouldUnregister: Bool,
         criteriaMode: CriteriaMode,
         delayError: Bool
    ) {
        self.mode = mode
        self.reValidateMode = reValidateMode
        self.resolver = resolver
        self.context = context
        self.shouldUnregister = shouldUnregister
        self.criteriaMode = criteriaMode
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
    _ options: ResolverOption<FieldName>
) async -> Result<ResolverValue<FieldName>, ResolverError<FieldName>> where FieldName: Hashable

public typealias ResolverValue = FormValue

public struct ResolverError<FieldName>: Error where FieldName: Hashable {
    let values: ResolverValue<FieldName>
    let errors: FormError<FieldName>
}

public enum CriteriaMode {
    case firstError
    case all
}

public struct ResolverOption<FieldName> {
    public let criteriaMode: CriteriaMode
    public let names: [FieldName]
}
