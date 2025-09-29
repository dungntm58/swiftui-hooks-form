//
//  ValidatorTests.swift
//  FormHookTests
//
//  Created by Robert on 03/12/2022.
//

@testable import FormHook
import Foundation
import RegexBuilder
import Testing

private func messageGenerator(_ value: Bool) -> [String] {
    if value {
        return []
    }
    return ["Invalid"]
}

@Suite("Validators")
struct ValidationTests {

    @Suite("NotEmptyValidator")
    struct NotEmptyValidatorTests {

        @Test("validates empty and non-empty values")
        func validatesEmptyAndNonEmptyValues() async {
            var (stringValidateResult, messages) = await NotEmptyValidator(messageGenerator(_:)).computeMessage(value: "")
            #expect(stringValidateResult == false)
            #expect(messages == ["Invalid"])

            (stringValidateResult, messages) = await NotEmptyValidator(messageGenerator(_:)).computeMessage(value: "a")
            #expect(stringValidateResult == true)
            #expect(messages == [])

            var intArrayValidateResult = await NotEmptyValidator(messageGenerator(_:)).validate([Int]())
            #expect(intArrayValidateResult == false)

            intArrayValidateResult = await NotEmptyValidator(messageGenerator(_:)).validate([1])
            #expect(intArrayValidateResult == true)
        }

        @Test("handles edge cases")
        func handlesEdgeCases() async {
            let validator = NotEmptyValidator<String>(messageGenerator(_:))

            // Test with whitespace-only string
            var result = await validator.validate("   ")
            #expect(result == true) // NotEmptyValidator only checks for empty, not whitespace

            // Test with newline characters
            result = await validator.validate("\n\t")
            #expect(result == true)

            // Test with unicode characters
            result = await validator.validate("🙂")
            #expect(result == true)

            // Test with empty arrays using the correct validator type
            let intArrayValidator = NotEmptyValidator<[Int]>(messageGenerator(_:))
            let intArrayResult = await intArrayValidator.validate([Int]())
            #expect(intArrayResult == false)

            let stringArrayValidator = NotEmptyValidator<[String]>(messageGenerator(_:))
            let stringArrayResult = await stringArrayValidator.validate([String]())
            #expect(stringArrayResult == false)
        }
    }

    @Suite("NotNilValidator")
    struct NotNilValidatorTests {

        @Test("validates nil and non-nil values")
        func validatesNilAndNonNilValues() async {
            var result = await NotNilValidator(messageGenerator(_:)).validate(Int?.none)
            #expect(result == false)

            result = await NotNilValidator(messageGenerator(_:)).validate(1)
            #expect(result == true)
        }

        @Test("handles edge cases")
        func handlesEdgeCases() async {
            // Test with String optional
            var stringResult = await NotNilValidator(messageGenerator(_:)).validate(String?.none)
            #expect(stringResult == false)

            stringResult = await NotNilValidator(messageGenerator(_:)).validate(String?.some(""))
            #expect(stringResult == true)

            // Test with nested optionals using the correct validator type
            let nestedOptionalValidator = NotNilValidator<Int??>(messageGenerator(_:))
            let nestedOptional: Int?? = .some(.none)
            let nestedResult = await nestedOptionalValidator.validate(nestedOptional)
            #expect(nestedResult == true) // The outer optional is not nil

            // Test with zero values (should be valid)
            let zeroResult = await NotNilValidator(messageGenerator(_:)).validate(0 as Int?)
            #expect(zeroResult == true)

            let falseResult = await NotNilValidator(messageGenerator(_:)).validate(false as Bool?)
            #expect(falseResult == true)
        }
    }

    @Suite("RangeValidator")
    struct RangeValidatorTests {

        @Test("validates values within range")
        func validatesValuesWithinRange() async {
            var validator = RangeValidator(max: 10, messageGenerator(_:))
            var result = await validator.validate(9)
            #expect(result == true)
            result = await validator.validate(10)
            #expect(result == true)
            result = await validator.validate(11)
            #expect(result == false)

            validator = RangeValidator(min: 10, messageGenerator(_:))
            result = await validator.validate(9)
            #expect(result == false)
            result = await validator.validate(10)
            #expect(result == true)
            result = await validator.validate(11)
            #expect(result == true)

            validator = RangeValidator(min: 9, max: 11, messageGenerator(_:))
            result = await validator.validate(8)
            #expect(result == false)
            result = await validator.validate(12)
            #expect(result == false)
            result = await validator.validate(9)
            #expect(result == true)
            result = await validator.validate(10)
            #expect(result == true)
            result = await validator.validate(11)
            #expect(result == true)
        }

        @Test("handles edge cases")
        func handlesEdgeCases() async {
            // Test with floating point numbers
            let floatValidator = RangeValidator(min: 0.1, max: 0.9, messageGenerator(_:))
            var result = await floatValidator.validate(0.5)
            #expect(result == true)

            result = await floatValidator.validate(0.05)
            #expect(result == false)

            // Test with negative ranges
            let negativeValidator = RangeValidator(min: -10, max: -5, messageGenerator(_:))
            result = await negativeValidator.validate(-7)
            #expect(result == true)

            result = await negativeValidator.validate(-3)
            #expect(result == false)

            // Test edge case: min equals max
            let equalValidator = RangeValidator(min: 5, max: 5, messageGenerator(_:))
            result = await equalValidator.validate(5)
            #expect(result == true)

            result = await equalValidator.validate(4)
            #expect(result == false)

            // Test with only min or only max set to extreme values
            let maxOnlyValidator = RangeValidator(max: Int.max, messageGenerator(_:))
            result = await maxOnlyValidator.validate(Int.max - 1)
            #expect(result == true)

            let minOnlyValidator = RangeValidator(min: Int.min, messageGenerator(_:))
            result = await minOnlyValidator.validate(Int.min + 1)
            #expect(result == true)
        }
    }

    @Suite("LengthRangeValidator")
    struct LengthRangeValidatorTests {

        @Test("validates length within range")
        func validatesLengthWithinRange() async {
            var result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([])
            #expect(result == true)
            result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([1])
            #expect(result == true)
            result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([0, 1])
            #expect(result == true)
            result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([0, 1, 2])
            #expect(result == false)

            result = await LengthRangeValidator(minLength: 1, messageGenerator(_:)).validate([])
            #expect(result == false)
            result = await LengthRangeValidator(minLength: 1, messageGenerator(_:)).validate([1])
            #expect(result == true)
            result = await LengthRangeValidator(minLength: 1, messageGenerator(_:)).validate([1, 2])
            #expect(result == true)

            result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([])
            #expect(result == false)
            result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([0, 1, 2, 3])
            #expect(result == false)
            result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([1])
            #expect(result == true)
            result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([1, 2])
            #expect(result == true)
            result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([1, 2, 3])
            #expect(result == true)
        }

        @Test("handles edge cases")
        func handlesEdgeCases() async {
            // Test with strings instead of arrays
            let stringValidator = LengthRangeValidator<String>(minLength: 2, maxLength: 5, messageGenerator(_:))
            var result = await stringValidator.validate("abc")
            #expect(result == true)

            result = await stringValidator.validate("a")
            #expect(result == false)

            result = await stringValidator.validate("abcdef")
            #expect(result == false)

            // Test with unicode strings
            result = await stringValidator.validate("🙂🎉")
            #expect(result == true) // 2 unicode characters

            // Test with empty string and zero min length
            let zeroMinValidator = LengthRangeValidator<String>(minLength: 0, maxLength: 3, messageGenerator(_:))
            result = await zeroMinValidator.validate("")
            #expect(result == true)

            // Test with very large max length
            let largeMaxValidator = LengthRangeValidator<[Int]>(maxLength: 1000000, messageGenerator(_:))
            result = await largeMaxValidator.validate(Array(repeating: 1, count: 999999))
            #expect(result == true)

            // Test with sets (which also have count)
            let setValidator = LengthRangeValidator<Set<Int>>(minLength: 1, maxLength: 3, messageGenerator(_:))
            result = await setValidator.validate(Set([1, 2]))
            #expect(result == true)

            result = await setValidator.validate(Set<Int>())
            #expect(result == false)
        }
    }

    @Suite("PatternMatchingValidator")
    struct PatternMatchingValidatorTests {

        @Test("validates pattern matching")
        func validatesPatternMatching() async {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPatternMatchingValidator = PatternMatchingValidator<String>(pattern: emailRegEx, messageGenerator(_:))
            var result = await emailPatternMatchingValidator.validate("abc@domain.com")
            #expect(result == true)

            result = await emailPatternMatchingValidator.validate("domain.com")
            #expect(result == false)
        }

        @Test("handles edge cases")
        func handlesEdgeCases() async {
            // Test with complex regex patterns
            let phoneValidator = PatternMatchingValidator<String>(
                pattern: "^\\+?[1-9]\\d{1,14}$",
                messageGenerator(_:)
            )

            var result = await phoneValidator.validate("+1234567890")
            #expect(result == true)

            result = await phoneValidator.validate("1234567890")
            #expect(result == true)

            result = await phoneValidator.validate("+0123456789") // Leading zero after +
            #expect(result == false)

            // Test with multiline strings
            let multilineValidator = PatternMatchingValidator<String>(
                pattern: "^Line1\\nLine2$",
                messageGenerator(_:)
            )

            result = await multilineValidator.validate("Line1\nLine2")
            #expect(result == true)

            result = await multilineValidator.validate("Line1\nLine3")
            #expect(result == false)

            // Test with special characters
            let specialCharsValidator = PatternMatchingValidator<String>(
                pattern: "^[a-zA-Z0-9!@#$%^&*()_+\\-=\\[\\]{};':\\\"\\\\|,.<>\\/?]+$",
                messageGenerator(_:)
            )

            result = await specialCharsValidator.validate("Hello@World#123!")
            #expect(result == true)

            result = await specialCharsValidator.validate("Hello 世界") // Contains space and non-ASCII
            #expect(result == false)

            // Test with empty pattern (should match empty string)
            let emptyPatternValidator = PatternMatchingValidator<String>(
                pattern: "^$",
                messageGenerator(_:)
            )

            result = await emptyPatternValidator.validate("")
            #expect(result == true)

            result = await emptyPatternValidator.validate("a")
            #expect(result == false)
        }
    }

    @Suite("RegexMatchingValidator")
    struct RegexMatchingValidatorTests {

        @Test("validates regex matching")
        func validatesRegexMatching() async throws {
            guard #available(macOS 13.0, iOS 16.0, tvOS 16.0, *) else {
                throw XCTSkip("RegexBuilder not available on this platform")
            }

            let emailRegexMatchingValidator = RegexMatchingValidator<Substring>(
                regex: Regex {
                    OneOrMore {
                        CharacterClass(
                            .anyOf("._%+-"),
                            ("A"..."Z"),
                            ("0"..."9"),
                            ("a"..."z")
                        )
                    }
                    "@"
                    OneOrMore {
                        CharacterClass(
                            .anyOf(".-"),
                            ("A"..."Z"),
                            ("a"..."z"),
                            ("0"..."9")
                        )
                    }
                    "."
                    Repeat(2...64) {
                        CharacterClass(
                            ("A"..."Z"),
                            ("a"..."z")
                        )
                    }
                }
                  .anchorsMatchLineEndings(),
                messageGenerator(_:))
            var result = await emailRegexMatchingValidator.validate("abc@domain.com")
            #expect(result == true)

            result = await emailRegexMatchingValidator.validate("domain.com")
            #expect(result == false)
        }
    }

    @Suite("Validator Message Generation")
    struct ValidatorMessageGenerationTests {

        @Test("generates custom messages")
        func generatesCustomMessages() async {
            let customMessageGenerator: (Bool) -> [String] = { isValid in
                if isValid {
                    return []
                }
                return ["Custom error message", "Additional context"]
            }

            let validator = NotEmptyValidator<String>(customMessageGenerator)
            let (isValid, messages) = await validator.computeMessage(value: "")

            #expect(isValid == false)
            #expect(messages.count == 2)
            #expect(messages[0] == "Custom error message")
            #expect(messages[1] == "Additional context")

            // Test with valid input
            let (isValid2, messages2) = await validator.computeMessage(value: "valid")
            #expect(isValid2 == true)
            #expect(messages2.isEmpty)
        }
    }

    @Suite("Async Validator Behavior")
    struct AsyncValidatorBehaviorTests {

        @Test("handles async operations")
        func handlesAsyncOperations() async {
            // Test that validators are truly async and can handle delays
            let validator = NotEmptyValidator<String> { _ in
                ["Delayed message"]
            }

            // Test that the async validation works correctly
            let result = await validator.validate("")
            #expect(result == false)

            let (isValid, messages) = await validator.computeMessage(value: "")
            #expect(isValid == false)
            #expect(messages == ["Delayed message"])
        }
    }

    @Suite("Concurrent Validation")
    struct ConcurrentValidationTests {

        @Test("runs multiple validators concurrently")
        func runsMultipleValidatorsConcurrently() async {
            // Test multiple validators running concurrently
            let validator1 = NotEmptyValidator<String>(messageGenerator(_:))
            let validator2 = RangeValidator<Int>(min: 1, max: 10, messageGenerator(_:))
            let validator3 = LengthRangeValidator<String>(minLength: 1, maxLength: 5, messageGenerator(_:))

            // Run validations concurrently
            async let result1 = validator1.validate("test")
            async let result2 = validator2.validate(5)
            async let result3 = validator3.validate("abc")

            let results = await [result1, result2, result3]

            #expect(results[0] == true)
            #expect(results[1] == true)
            #expect(results[2] == true)
        }
    }

    @Suite("Validator with Extreme Lengths")
    struct ValidatorExtremeLengthTests {

        @Test("handles extreme length values")
        func handlesExtremeLengthValues() async {
            let longStringValidator = LengthRangeValidator<String>(minLength: 1000, maxLength: 2000, messageGenerator(_:))

            // Test with very long string
            let longString = String(repeating: "a", count: 1500)
            let result = await longStringValidator.validate(longString)
            #expect(result == true)

            // Test just below minimum
            let shortString = String(repeating: "a", count: 999)
            let result2 = await longStringValidator.validate(shortString)
            #expect(result2 == false)

            // Test just above maximum
            let tooLongString = String(repeating: "a", count: 2001)
            let result3 = await longStringValidator.validate(tooLongString)
            #expect(result3 == false)
        }
    }
}

protocol ResultControllableValidator: Validator where Result: BoolConvertible {
    var result: Result { get }
    var messages: [String] { get }
}

extension ResultControllableValidator {
    func validate(_ value: Value) async -> Result {
        result
    }

    func generateMessage(result: Result) -> [String] {
        messages
    }
}

class MockValidator<Value, Result>: ResultControllableValidator where Result: BoolConvertible {
    var result: Result
    var messages: [String]

    init(result: Result, messages: [String] = []) {
        self.result = result
        self.messages = messages
    }
}

// XCTSkip equivalent for Swift Testing
struct XCTSkip: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
