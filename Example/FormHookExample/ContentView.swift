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
    case firstName = "First name"
    case lastName = "Last name"
    case password = "Password"
    case gender = "Gender"
    case email = "Email"
    case phone = "Phone"
    case dob = "Date of birth"

    func messages(for validationResult: Bool) -> [String] {
        if validationResult {
            return []
        }
        return ["\(rawValue) is required"]
    }
}

enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
}

struct ContentView: View {
    
    @FocusState var focusField: FormFieldName?
    
    @ViewBuilder
    var body: some View {
        ContextualForm(focusedFieldBinder: $focusField) { form in
            Form {
                Section("Name") {
                    firstNameView
                    lastNameView
                }
                
                Section("Password") {
                    passwordView
                }
                
                Section("Basic Info") {
                    genderView
                    dobView
                    emailView
                    phoneView
                }
                
                Button("Submit") {
                    focusField = nil
                    hideKeyboard()
                    Task {
                        try await form.handleSubmit(onValid: { _, _ in
                            
                        }, onInvalid: { _, errors in
                            
                        })
                    }
                }
            }
        }
    }
    
    var firstNameView: some View {
        Controller(
            name: FormFieldName.firstName,
            defaultValue: "",
            rules: NotEmptyValidator(FormFieldName.firstName.messages(for:)),
            fieldOrdinal: 0
        ) { field, fieldState, _ in
            let textField = TextField(field.name.rawValue, text: field.value)
                .focused($focusField, equals: field.name)
                .submitLabel(.next)
            
            if let error = fieldState.error.first {
                VStack(alignment: .leading) {
                    textField
                    Text(error)
                        .font(.system(size: 10)).foregroundColor(.red)
                }
            } else {
                textField
            }
        }
    }
    
    var lastNameView: some View {
        Controller(
            name: FormFieldName.lastName,
            defaultValue: "",
            rules: NotEmptyValidator(FormFieldName.lastName.messages(for:)),
            fieldOrdinal: 1
        ) { field, fieldState, _ in
            let textField = TextField(field.name.rawValue, text: field.value)
                .focused($focusField, equals: field.name)
                .submitLabel(.next)
            
            if let error = fieldState.error.first {
                VStack(alignment: .leading) {
                    textField
                    Text(error)
                        .font(.system(size: 10)).foregroundColor(.red)
                }
            } else {
                textField
            }
        }
    }
    
    var passwordView: some View {
        Controller(
            name: FormFieldName.password,
            defaultValue: "",
            rules: NotEmptyValidator(FormFieldName.password.messages(for:)),
            fieldOrdinal: 2
        ) { field, fieldState, _ in
            let textField = SecureField(field.name.rawValue, text: field.value)
                .focused($focusField, equals: field.name)
                .textContentType(.password)
                .submitLabel(.go)
            
            if let error = fieldState.error.first {
                VStack(alignment: .leading) {
                    textField
                    Text(error)
                        .font(.system(size: 10)).foregroundColor(.red)
                }
            } else {
                textField
            }
        }
    }
    
    var genderView: some View {
        Controller(
            name: FormFieldName.gender,
            defaultValue: Gender.male,
            fieldOrdinal: 3
        ) { field, fieldState, _ in
            let picker = Picker(field.name.rawValue, selection: field.value) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender.rawValue)
                }
            }
            
            if let error = fieldState.error.first {
                VStack(alignment: .leading) {
                    picker
                    Text(error)
                        .font(.system(size: 10)).foregroundColor(.red)
                }
            } else {
                picker
            }
        }
    }
    
    var dobView: some View {
        Controller(
            name: FormFieldName.dob,
            defaultValue: Calendar.current.startOfDay(for: Date()),
            fieldOrdinal: 4
        ) { field, fieldState, _ in
            let picker = DatePicker(
                selection: field.value,
                in: ...Date.now,
                displayedComponents: .date
            ) {
                Text(field.name.rawValue)
            }
                .environment(\.locale, Locale.init(identifier: "en"))
            
            if let error = fieldState.error.first {
                VStack(alignment: .leading) {
                    picker
                    Text(error)
                        .font(.system(size: 10)).foregroundColor(.red)
                }
            } else {
                picker
            }
        }
    }
    
    @ViewBuilder
    var emailView: some View {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPatternValidator = PatternMatchingValidator<String>(pattern: emailRegEx) { result in
            if result {
                return []
            }
            return ["Email is not correct"]
        }
        
        Controller(
            name: FormFieldName.email,
            defaultValue: "",
            rules: NotEmptyValidator(FormFieldName.email.messages(for:))
                .and(validator: emailPatternValidator),
            fieldOrdinal: 5
        ) { field, fieldState, _ in
            let textField = TextField(field.name.rawValue, text: field.value)
                .focused($focusField, equals: field.name)
                .keyboardType(.emailAddress)
                .submitLabel(.next)
            
            if let error = fieldState.error.first {
                VStack(alignment: .leading) {
                    textField
                    Text(error)
                        .font(.system(size: 10)).foregroundColor(.red)
                }
            } else {
                textField
            }
        }
    }
    
    @ViewBuilder
    var phoneView: some View {
        let phoneRegEx = "^[0-9+]{0,1}+[0-9]{5,16}$"
        let phonePatternValidator = PatternMatchingValidator<String>(pattern: phoneRegEx) { result in
            if result {
                return []
            }
            return ["Phone is not correct"]
        }
        
        Controller(
            name: FormFieldName.phone,
            defaultValue: "",
            rules: NotEmptyValidator(FormFieldName.phone.messages(for:)).and(validator: phonePatternValidator),
            fieldOrdinal: 6
        ) { field, fieldState, _ in
            let textField = TextField(field.name.rawValue, text: field.value)
                .focused($focusField, equals: field.name)
                .keyboardType(.numberPad)
                .submitLabel(.next)
            
            if let error = fieldState.error.first {
                VStack(alignment: .leading) {
                    textField
                    Text(error)
                        .font(.system(size: 10)).foregroundColor(.red)
                }
            } else {
                textField
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
