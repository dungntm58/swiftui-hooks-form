//
//  ValidatorTests.swift
//  FormHookTests
//
//  Created by Robert on 03/12/2022.
//

import Foundation
import XCTest

@testable import FormHook

class ValidationTests: XCTestCase {
    func testNoEmptyValidator() async {
        var (stringValidateResult, messages) = await NotEmptyValidator(messageGenerator(_:)).computeMessage(value: "")
        XCTAssertFalse(stringValidateResult)
        XCTAssertTrue(messages == ["Invalid"])

        (stringValidateResult, messages) = await NotEmptyValidator(messageGenerator(_:)).computeMessage(value: "a")
        XCTAssertTrue(stringValidateResult)
        XCTAssertTrue(messages == [])

        var intArrayValidateResult = await NotEmptyValidator(messageGenerator(_:)).validate([Int]())
        XCTAssertFalse(intArrayValidateResult)

        intArrayValidateResult = await NotEmptyValidator(messageGenerator(_:)).validate([1])
        XCTAssertTrue(intArrayValidateResult)
    }

    func testNotNilValidator() async {
        var result = await NotNilValidator(messageGenerator(_:)).validate(Int?.none)
        XCTAssertFalse(result)

        result = await NotNilValidator(messageGenerator(_:)).validate(1)
        XCTAssertTrue(result)
    }

    func testRangeValidator() async {
        var validator = RangeValidator(max: 10, messageGenerator(_:))
        var result = await validator.validate(9)
        XCTAssertTrue(result)
        result = await validator.validate(10)
        XCTAssertTrue(result)
        result = await validator.validate(11)
        XCTAssertFalse(result)

        validator = RangeValidator(min: 10, messageGenerator(_:))
        result = await validator.validate(9)
        XCTAssertFalse(result)
        result = await validator.validate(10)
        XCTAssertTrue(result)
        result = await validator.validate(11)
        XCTAssertTrue(result)

        validator = RangeValidator(min: 9, max: 11, messageGenerator(_:))
        result = await validator.validate(8)
        XCTAssertFalse(result)
        result = await validator.validate(12)
        XCTAssertFalse(result)
        result = await validator.validate(9)
        XCTAssertTrue(result)
        result = await validator.validate(10)
        XCTAssertTrue(result)
        result = await validator.validate(11)
        XCTAssertTrue(result)
    }

    func testLengthValidator() async {
        var result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([1])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([0, 1])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([0, 1, 2])
        XCTAssertFalse(result)

        result = await LengthRangeValidator(minLength: 1, messageGenerator(_:)).validate([])
        XCTAssertFalse(result)
        result = await LengthRangeValidator(minLength: 1, messageGenerator(_:)).validate([1])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(minLength: 1, messageGenerator(_:)).validate([1, 2])
        XCTAssertTrue(result)

        result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([])
        XCTAssertFalse(result)
        result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([0, 1, 2, 3])
        XCTAssertFalse(result)
        result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([1])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([1, 2])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([1, 2, 3])
        XCTAssertTrue(result)
    }
}

private func messageGenerator(_ value: Bool) -> [String] {
    if value {
        return []
    }
    return ["Invalid"]
}
