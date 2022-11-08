//
//  ContentView.swift
//  FormHookExample
//
//  Created by Robert on 06/11/2022.
//

import SwiftUI
import Hooks
import FormHook

enum FormFieldName: String, CaseIterable {
    case username
    case password

    var title: String {
        switch self {
        case .username:
            return "Username"
        case .password:
            return "Password"
        }
    }

    func messages(for validationResult: Bool) -> [String] {
        if validationResult {
            return []
        }
        switch self {
        case .username:
            return ["Username is required"]
        case .password:
            return ["Password is required"]
        }
    }
}

struct ContentView: HookView {
    
    @FocusState var focusField: FormFieldName?
    
    @ViewBuilder
    var hookBody: some View {
        let form: FormControl<FormFieldName> = useForm()
        Context.Provider(value: form) {
            Form {
                VStack(spacing: 16) {
                    ForEach(FormFieldName.allCases, id: \.self) { name in
                        Controller(
                            name: name,
                            defaultValue: "",
                            rules: NotEmptyValidator(name.messages(for:))
                        ) { field, fieldState, _ in
                            switch name {
                            case .username:
                                TextField(name.title, text: field.value)
                                    .focused($focusField, equals: name)
                                    .textContentType(.username)
                                    .submitLabel(.next)
                            case .password:
                                SecureField(name.title, text: field.value)
                                    .focused($focusField, equals: name)
                                    .textContentType(.password)
                                    .submitLabel(.go)
                            }
                            
                            if let error = fieldState.error.first {
                                Text(error)
                            }
                        }
                    }
                    
                    Button("Submit") {
                        self.focusField = nil
                        hideKeyboard()
                        Task {
                            do {
                                try await form.handleSubmit(onValid: { _, _ in
                                    
                                }, onInvalid: { _, errors in
                                    self.focusField = FormFieldName.allCases.first(where: errors.errorFields.contains(_:))
                                })
                            } catch {}
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
