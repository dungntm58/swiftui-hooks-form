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
    var firstValidator: MockValidator<Any, Bool>!
    var secondValidator: MockValidator<Any, Bool>!
    
    override func setUp() {
        firstValidator = MockValidator<Any, Bool>(result: true)
        secondValidator = MockValidator<Any, Bool>(result: true)
    }
    
    func testCompoundValidatorWithAndOperator() async {
        let compound1 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        firstValidator.messages = ["First success"]
        secondValidator.messages = ["Second success"]
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssert(messages1 == [
            "First success",
            "Second success"
        ])
        
        firstValidator.result = false
        firstValidator.messages = ["First failure"]
        let compound2 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssert(messages2 == [
            "First failure"
        ])
        
        secondValidator.result = false
        secondValidator.messages = ["Second failure"]
        let compound3 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssert(messages3 == [
            "First failure"
        ])
        
        firstValidator.result = true
        firstValidator.messages = ["First success"]
        let compound4 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages4) = await compound4.computeMessage(value: ())
        XCTAssert(messages4 == [
            "First success",
            "Second failure"
        ])
    }
    
    func testCompoundValidatorWithOrOperator() async {
        let compound1 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        firstValidator.messages = ["First success"]
        secondValidator.messages = ["Second success"]
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssert(messages1 == [
            "First success"
        ])
        
        firstValidator.result = false
        firstValidator.messages = ["First failure"]
        let compound2 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssert(messages2 == [
            "First failure",
            "Second success"
        ])
        
        secondValidator.result = false
        secondValidator.messages = ["Second failure"]
        let compound3 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssert(messages3 == [
            "First failure",
            "Second failure"
        ])
        
        firstValidator.result = true
        firstValidator.messages = ["First success"]
        let compound4 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages4) = await compound4.computeMessage(value: ())
        XCTAssert(messages4 == [
            "First success"
        ])
    }
    
    func testCompoundValidatorWithAndOperatorGetAllMessages() async {
        let compound1 = firstValidator.and(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        firstValidator.messages = ["First success"]
        secondValidator.messages = ["Second success"]
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssert(messages1 == [
            "First success",
            "Second success"
        ])
        
        firstValidator.result = false
        firstValidator.messages = ["First failure"]
        let compound2 = firstValidator.and(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssert(messages2 == [
            "First failure",
            "Second success"
        ])
        
        secondValidator.result = false
        secondValidator.messages = ["Second failure"]
        let compound3 = firstValidator.and(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssert(messages3 == [
            "First failure",
            "Second failure"
        ])
    }
    
    func testCompoundValidatorWithOrOperatorGetAllMessages() async {
        let compound1 = firstValidator.or(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        firstValidator.messages = ["First success"]
        secondValidator.messages = ["Second success"]
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssert(messages1 == [
            "First success",
            "Second success"
        ])
        
        firstValidator.result = false
        firstValidator.messages = ["First failure"]
        let compound2 = firstValidator.or(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssert(messages2 == [
            "First failure",
            "Second success"
        ])
        
        secondValidator.result = false
        secondValidator.messages = ["Second failure"]
        let compound3 = firstValidator.or(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssert(messages3 == [
            "First failure",
            "Second failure"
        ])
    }
}
