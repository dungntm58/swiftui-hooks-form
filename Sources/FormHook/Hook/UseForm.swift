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
    defaultValues: [FieldName: Any]? = nil
) -> Form<FieldName> where FieldName: Hashable {
    let state = useState(FormState<FieldName>())
    return Form(mode: mode, reValidateMode: reValidateMode, defaultValues: defaultValues, state: state)
}

public struct Mode: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let onSubmit = Mode(rawValue: 1 << 0)
    public static let onBlur = Mode(rawValue: 1 << 1)
    public static let onChange = Mode(rawValue: 1 << 2)
    public static let onTouched = Mode(rawValue: 1 << 3)
    public static let all: Mode = [onChange, onBlur]
}

public struct ReValidateMode: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let onChange = ReValidateMode(rawValue: 1 << 0)
    public static let onBlur = ReValidateMode(rawValue: 1 << 1)
    public static let onSubmit = ReValidateMode(rawValue: 1 << 2)
    public static let all: ReValidateMode = [onChange, onBlur, onSubmit]
}
