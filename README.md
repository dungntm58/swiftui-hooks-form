<h1 align="center">SwiftUI Hooks Form</h1>
<p align="center">A SwiftUI implementation of <a href="https://react-hook-form.com/get-started">React Hooks Form</a>.</p>
<p align="center">Performant, flexible and extensible forms with easy-to-use validation.</p>
<p align="center"><a href="https://dungntm58.github.io/swiftui-hooks-form/documentation/formhook">📔 API Reference</a></p>
<p align="center">
  <a href="https://github.com/dungntm58/swiftui-hooks-form/actions"><img alt="test" src="https://github.com/dungntm58/swiftui-hooks-form/workflows/test/badge.svg"></a>
  <a href="https://github.com/dungntm58/swiftui-hooks-form/releases/latest"><img alt="release" src="https://img.shields.io/github/v/release/dungntm58/swiftui-hooks-form.svg"/></a>
  <a href="https://developer.apple.com/swift"><img alt="Swift5" src="https://img.shields.io/badge/language-Swift5-orange.svg"></a>
  <a href="https://developer.apple.com"><img alt="Platform" src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS-green.svg"></a>
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/badge/license-MIT-black.svg"></a>
</p>

---

- [Introduction](#introduction)
- [Getting Started](#getting-started)
- [API](#hooks-api)
- [License](#license)

---

## Introduction

SwiftUI Hooks Form is a Swift implementation of React Hook Form

This library continues working from <a href="https://github.com/ra1028/swiftui-hooks">SwiftUI Hooks</a>. Thank ra1028 for developing the library.

---

## Getting Started

### Requirements

|       |Minimum Version|
|------:|--------------:|
|Swift  |5.7            |
|Xcode  |14.0           |
|iOS    |13.0           |
|macOS  |10.15          |
|tvOS   |13.0           |

## Installation

The module name of the package is `FormHook`. Choose one of the instructions below to install and add the following import statement to your source code.

```swift
import FormHook
```

#### [Xcode Package Dependency](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

From Xcode menu: `File` > `Swift Packages` > `Add Package Dependency`

```text
https://github.com/dungntm58/swiftui-hooks-form
```

#### [Swift Package Manager](https://www.swift.org/package-manager)

In your `Package.swift` file, first add the following to the package `dependencies`:

```swift
.package(url: "https://github.com/dungntm58/swiftui-hooks-form"),
```

And then, include "Hooks" as a dependency for your target:

```swift
.target(name: "<target>", dependencies: [
    .product(name: "FormHook", package: "swiftui-hooks-form"),
]),
```

### Documentation

- [API Reference](https://dungntm58.github.io/swiftui-hooks-form/documentation/formhook)
- [Example apps](Example)
- [Migration Guide](#migration-guide)

---

## Hooks API

👇 Click to open the description.

<details>
<summary><CODE>useForm</CODE></summary>

```swift
func useForm<FieldName>(
    mode: Mode = .onSubmit,
    reValidateMode: ReValidateMode = .onChange,
    resolver: Resolver<FieldName>? = nil,
    context: Any? = nil,
    shouldUnregister: Bool = true,
    criteriaMode: CriteriaMode = .all,
    delayErrorInNanoseconds: UInt64 = 0
) -> FormControl<FieldName> where FieldName: Hashable
```

`useForm` is a custom hook for managing forms with ease. It returns a `FormControl` instance.

</details>

<details>
<summary><CODE>useController</CODE></summary>

```swift
func useController<FieldName, Value>(
    name: FieldName,
    defaultValue: Value,
    rules: any Validator<Value>,
    shouldUnregister: Bool = false
) -> ControllerRenderOption<FieldName, Value> where FieldName: Hashable
```

This custom hook powers `Controller`. Additionally, it shares the same props and methods as `Controller`. It's useful for creating reusable `Controlled` input.

`useController` must be called in a `Context` scope.

```swift
enum FieldName: Hashable {
    case username
    case password
}

@ViewBuilder
var hookBody: some View {
    let form: FormControl<FieldName> = useForm()
    Context.Provider(value: form) {
        let (field, fieldState, formState) = useController(name: FieldName.username, defaultValue: "")
        TextField("Username", text: field.value)
    }
}

// this code achieves the same

@ViewBuilder
var body: some View {
    ContextualForm(...) { form in
        let (field, fieldState, formState) = useController(name: FieldName.username, defaultValue: "")
        TextField("Username", text: field.value)
    }
}
```

</details>

---

## SwiftUI Component
👇 Click to open the description.

<details>
<summary><CODE>ContextualForm</CODE></summary>

```swift
struct ContextualForm<Content, FieldName>: View where Content: View, FieldName: Hashable {
    init(mode: Mode = .onSubmit,
        reValidateMode: ReValidateMode = .onChange,
        resolver: Resolver<FieldName>? = nil,
        context: Any? = nil,
        shouldUnregister: Bool = true,
        shouldFocusError: Bool = true,
        delayErrorInNanoseconds: UInt64 = 0,
        @_implicitSelfCapture onFocusField: @escaping (FieldName) -> Void,
        @ViewBuilder content: @escaping (FormControl<FieldName>) -> Content
    )

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    init(mode: Mode = .onSubmit,
        reValidateMode: ReValidateMode = .onChange,
        resolver: Resolver<FieldName>? = nil,
        context: Any? = nil,
        shouldUnregister: Bool = true,
        shouldFocusError: Bool = true,
        delayErrorInNanoseconds: UInt64 = 0,
        focusedFieldBinder: FocusState<FieldName?>.Binding,
        @ViewBuilder content: @escaping (FormControl<FieldName>) -> Content
    )
```
It wraps a call of `useForm` inside the `hookBody` and passes the FormControl value to a `Context.Provider<Form>`

It is identical to

```swift
let form: FormControl<FieldName> = useForm(...)
Context.Provider(value: form) {
    ...
}
```

</details>

<details>
<summary><CODE>Controller</CODE></summary>

### Controller
```swift
import SwiftUI

struct Controller<Content, FieldName, Value>: View where Content: View, FieldName: Hashable {
    init(
        name: FieldName,
        defaultValue: Value,
        rules: any Validator<Value> = NoopValidator(),
        @ViewBuilder render: @escaping (ControllerRenderOption<FieldName, Value>) -> Content
    )
}
```

### FieldOption

```swift
struct FieldOption<FieldName, Value> {
    let name: FieldName
    let value: Binding<Value>
}
```

### ControllerRenderOption

```swift
typealias ControllerRenderOption<FieldName, Value> = (field: FieldOption<FieldName, Value>, fieldState: FieldState, formState: FormState<FieldName>) where FieldName: Hashable
```

It wraps a call of `useController` inside the `hookBody`. Like `useController`, you guarantee `Controller` must be used in a `Context` scope.

</details>

---

## Examples

### Basic Form with Validation

```swift
import SwiftUI
import FormHook

enum FieldName: Hashable {
    case email
    case password
}

struct LoginForm: View {
    var body: some View {
        ContextualForm { form in
            VStack(spacing: 16) {
                Controller(
                    name: FieldName.email,
                    defaultValue: "",
                    rules: CompositeValidator(
                        validators: [
                            RequiredValidator(),
                            EmailValidator()
                        ]
                    )
                ) { (field, fieldState, formState) in
                    VStack(alignment: .leading) {
                        TextField("Email", text: field.value)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        if let error = fieldState.error?.first {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }

                Controller(
                    name: FieldName.password,
                    defaultValue: "",
                    rules: CompositeValidator(
                        validators: [
                            RequiredValidator(),
                            MinLengthValidator(length: 8)
                        ]
                    )
                ) { (field, fieldState, formState) in
                    VStack(alignment: .leading) {
                        SecureField("Password", text: field.value)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        if let error = fieldState.error?.first {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }

                Button("Login") {
                    Task {
                        try await form.handleSubmit { values, errors in
                            print("Login successful:", values)
                        }
                    }
                }
                .disabled(!formState.isValid)
            }
            .padding()
        }
    }
}
```

### Advanced Form with Custom Validation

```swift
import SwiftUI
import FormHook

struct RegistrationForm: View {
    @FocusState private var focusedField: FieldName?

    var body: some View {
        ContextualForm(
            focusedFieldBinder: $focusedField
        ) { form in
            VStack(spacing: 20) {
                // Form fields here...

                Button("Register") {
                    Task {
                        do {
                            try await form.handleSubmit(
                                onValid: { values, _ in
                                    await registerUser(values)
                                },
                                onInvalid: { _, errors in
                                    print("Validation errors:", errors)
                                }
                            )
                        } catch {
                            print("Registration failed:", error)
                        }
                    }
                }
                .disabled(formState.isSubmitting)
            }
        }
    }

    private func registerUser(_ values: FormValue<FieldName>) async {
        // Registration logic
    }
}
```

---

## Performance Guidelines

- **Validation**: Use async validators for network-dependent validation
- **Field Registration**: Prefer `useController` over direct field registration for better performance
- **Focus Management**: Utilize the built-in focus management for better UX
- **Error Handling**: Implement proper error boundaries for production apps

---

## Migration Guide

### From Previous Versions

#### Breaking Changes in v2.0

1. **Module Rename**: The module is now called `FormHook` instead of `Hooks`
2. **File Structure**: Internal files have been reorganized for better maintainability
3. **Type Safety**: Improved type safety with better generic constraints

#### Migration Steps

1. Update your import statements:
   ```swift
   // Before
   import Hooks

   // After
   import FormHook
   ```

2. API References remain the same - no changes needed to your form implementations

3. If you were importing internal types, they may have moved:
   - `Types.swift` → `FormTypes.swift`
   - Form-related types are now in dedicated files

#### New Features

- **Enhanced Type Safety**: Better compile-time type checking
- **Improved Validation**: Consolidated validation patterns for better performance
- **Better Error Messages**: More descriptive error messages and debugging info

### Troubleshooting

#### Common Issues

1. **Import Errors**: Make sure you're importing `FormHook` not `Hooks`
2. **Field Focus**: Use `FocusState` binding for iOS 15+ focus management
3. **Validation Performance**: Consider using `delayErrorInNanoseconds` for expensive validations

#### Getting Help

- Check the [API Reference](https://dungntm58.github.io/swiftui-hooks-form/documentation/formhook)
- Look at [Example implementations](Example)
- File issues on [GitHub](https://github.com/dungntm58/swiftui-hooks-form/issues)

---

## Acknowledgements

- [React Hooks](https://reactjs.org/docs/hooks-intro.html)
- [React Hooks Form](https://react-hook-form.com)

---

## License

[MIT © Dung Nguyen](LICENSE)

---
