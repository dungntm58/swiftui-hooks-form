//
//  CompoundValidatorTests.swift
//  FormHookTests
//
//  Created by Robert on 27/12/2022.
//

import Foundation
import XCTest

@testable import FormHook

class CompoundValidatorTests: XCTestCase {
    func testCompoundValidatorWithAndOperator1() async {
        let firstValidator = MockValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockValidator<Any, Bool>(result: true, messages: ["Second success"])
        let compound1 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssert(messages1 == [
            "First success",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithAndOperator2() async {
        let firstValidator = MockValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockValidator<Any, Bool>(result: true, messages: ["Second success"])
        let compound2 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssert(messages2 == [
            "First failure"
        ])
    }
    
    func testCompoundValidatorWithAndOperator3() async {
        let firstValidator = MockValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockValidator<Any, Bool>(result: false, messages: ["Second failure"])
        let compound3 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssert(messages3 == [
            "First failure"
        ])
    }
    
    func testCompoundValidatorWithAndOperator4() async {
        let firstValidator = MockValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockValidator<Any, Bool>(result: false, messages: ["Second failure"])
        let compound4 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages4) = await compound4.computeMessage(value: ())
        XCTAssert(messages4 == [
            "First success",
            "Second failure"
        ])
    }
    
    func testCompoundValidatorWithOrOperator1() async {
        let firstValidator = MockValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockValidator<Any, Bool>(result: true, messages: ["Second success"])
        let compound1 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssert(messages1 == [
            "First success"
        ])
    }
    
    func testCompoundValidatorWithOrOperator2() async {
        let firstValidator = MockValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockValidator<Any, Bool>(result: true, messages: ["Second success"])
        let compound2 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssert(messages2 == [
            "First failure",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithOrOperator3() async {
        let firstValidator = MockValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockValidator<Any, Bool>(result: false, messages: ["Second failure"])
        let compound3 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssert(messages3 == [
            "First failure",
            "Second failure"
        ])
    }
    
    func testCompoundValidatorWithOrOperator4() async {
        let firstValidator = MockValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockValidator<Any, Bool>(result: false, messages: ["Second failure"])
        let compound4 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages4) = await compound4.computeMessage(value: ())
        XCTAssert(messages4 == [
            "First success"
        ])
    }
    
    func testCompoundValidatorWithAndOperatorGetAllMessages1() async {
        let firstValidator = MockValidator<Any, Bool>(result: true)
        let secondValidator = MockValidator<Any, Bool>(result: true)
        let compound1 = firstValidator.and(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        firstValidator.messages = ["First success"]
        secondValidator.messages = ["Second success"]
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssert(messages1 == [
            "First success",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithAndOperatorGetAllMessages2() async {
        let firstValidator = MockValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockValidator<Any, Bool>(result: true, messages: ["Second success"])
        let compound2 = firstValidator.and(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssert(messages2 == [
            "First failure",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithAndOperatorGetAllMessages3() async {
        let firstValidator = MockValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockValidator<Any, Bool>(result: false, messages: ["Second failure"])
        let compound3 = firstValidator.and(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssert(messages3 == [
            "First failure",
            "Second failure"
        ])
    }
    
    func testCompoundValidatorWithOrOperatorGetAllMessages1() async {
        let firstValidator = MockValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockValidator<Any, Bool>(result: true, messages: ["Second success"])
        let compound1 = firstValidator.or(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        firstValidator.messages = ["First success"]
        secondValidator.messages = ["Second success"]
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssert(messages1 == [
            "First success",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithOrOperatorGetAllMessages2() async {
        let firstValidator = MockValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockValidator<Any, Bool>(result: true, messages: ["Second success"])
        let compound2 = firstValidator.or(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssert(messages2 == [
            "First failure",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithOrOperatorGetAllMessages3() async {
        let firstValidator = MockValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockValidator<Any, Bool>(result: false, messages: ["Second failure"])
        let compound3 = firstValidator.or(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssert(messages3 == [
            "First failure",
            "Second failure"
        ])
    }
}
