<h1 align="center">SwiftUI Hooks Form</h1>
<p align="center">A SwiftUI implementation of <a href="https://react-hook-form.com/get-started">React Hooks Form</a>.</p>
<p align="center">Performant, flexible and extensible forms with easy-to-use validation.</p>
<p align="center"><a href="https://dungntm58.github.io/swiftui-hooks-form/documentation/hooks">📔 API Reference</a></p>
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

- [API Reference](https://dungntm58.github.io/swiftui-hooks-form/documentation/hooks)
- [Example apps](Examples)

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
    delayError: Bool = false
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
```

</details>

---

## SwiftUI Component
👇 Click to open the description.

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

## Acknowledgements

- [React Hooks](https://reactjs.org/docs/hooks-intro.html)
- [React Hooks Form](https://react-hook-form.com)

---

## License

[MIT © Dung Nguyen](LICENSE)

---