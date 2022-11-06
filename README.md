<h1 align="center">SwiftUI Hooks Form</h1>
<p align="center">A SwiftUI implementation of <a href="https://react-hook-form.com/get-started">React Hooks Form</a>.</p>
<p align="center">Performant, flexible and extensible forms with easy-to-use validation.</p>
<p align="center"><a href="https://dungntm58.github.io/swiftui-hooks-form/documentation/hooks">📔 API Reference</a></p>
<p align="center">
  <a href="https://github.com/dungntm58/swiftui-hooks-form/actions"><img alt="test" src="https://github.com/dungntm58/swiftui-hooks-form/workflows/test/badge.svg"></a>
  <a href="https://github.com/dungntm58/swiftui-hooks-form/releases/latest"><img alt="release" src="https://img.shields.io/github/v/release/dungntm58/swiftui-hooks-form.svg"/></a>
  <a href="https://developer.apple.com/swift"><img alt="Swift5" src="https://img.shields.io/badge/language-Swift5-orange.svg"></a>
  <a href="https://developer.apple.com"><img alt="Platform" src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C-green.svg"></a>
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
|Swift  |5.6            |
|Xcode  |13.3           |
|iOS    |13.0           |
|macOS  |10.15          |
|tvOS   |13.0           |
|watchOS|6.0            |

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
let form = useForm()
```

TBD

</details>

---

## Acknowledgements

- [React Hooks](https://reactjs.org/docs/hooks-intro.html)
- [React Hooks Form](https://react-hook-form.com)

---

## License

[MIT © Dung Nguyen](LICENSE)

---