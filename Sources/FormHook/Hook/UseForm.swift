//
//  UseForm.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import Hooks

public func useForm<FieldName>(
    updateStrategy: HookUpdateStrategy?,
    mode: Mode = .onSubmit,
    reValidateMode: ReValidateMode = .onChange,
    defaultValues: [FieldName: Any]? = nil
) -> Form<FieldName> where FieldName: Hashable {
    useHook(
        FormHook(
            updateStrategy: updateStrategy,
            mode: mode,
            reValidateMode: reValidateMode,
            defaultValues: defaultValues
        )
    )
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

private struct FormHook<FieldName>: Hook where FieldName: Hashable {
    let updateStrategy: Hooks.HookUpdateStrategy?
    let mode: Mode
    let reValidateMode: ReValidateMode
    let defaultValues: [FieldName: Any]?

    func makeState() -> Ref {
        .init(state: .init())
    }

    func value(coordinator: Coordinator) -> Form<FieldName> {
        .init(
            initialState: coordinator.state.state,
            mode: mode,
            reValidateMode: reValidateMode,
            defaultValues: defaultValues
        ) { state, needsUpdateView in
            if coordinator.state.isDisposed {
                return
            }
            coordinator.state.state = state
            guard needsUpdateView else {
                return
            }
            if Thread.current.isMainThread {
                coordinator.updateView()
            } else {
                DispatchQueue.main.async {
                    coordinator.updateView()
                }
            }
        }
    }

    func dispose(state: Ref) {
        state.isDisposed = true
    }
}

extension FormHook {
    class Ref {
        var state: FormState<FieldName>
        var isDisposed: Bool

        init(state: FormState<FieldName>) {
            self.state = state
            self.isDisposed = false
        }
    }
}
