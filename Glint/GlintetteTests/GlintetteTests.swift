//
//  GlintetteTests.swift
//  GlintetteTests
//
//  Created by Marc Prud'hommeaux on 4/29/17.
//  Copyright © 2017 Glimpse I/O. All rights reserved.
//

import XCTest
@testable import Glintette
import Glib
import KanjiScript
import BricBrac

class GlintetteTests: XCTestCase {
    let session = GlintSession()
    
    func testSession<R: GlintRequest>(line: UInt = #line, count: Int = 1, timeout: Double = 30, validator: @escaping (R, R.Response) -> Bool, request: () -> R) {
        var xps: [XCTestExpectation] = Array()
        
        for _ in 1...count {
            let req = request()
            let xp = expectation(description: "should get response")
            session.sendRequest(req) { (response: Result<R.Response>) in
                XCTAssertNil(response.error, "Received error: \(String(describing: response.error))", line: line)
                if let value = response.value {
                    XCTAssertTrue(validator(req, value), "validator failed for \(type(of: req)) and \(type(of: value))", line: line)
                } else {
                    XCTFail("no response", line: line)
                }
                xp.fulfill()

            }
            xps.append(xp)
        }
        
//        dbg("waiting for: \(xps.count)")
        wait(for: xps, timeout: timeout)
//        dbg("done waiting for: \(xps.count)")
    }
    
    func testSessionValue<R: GlintRequest>(line: UInt = #line, count: Int = 1, _ request: @autoclosure () -> R, validator: @escaping (R.Response) -> Bool) {
        testSession(line: line, count: count, validator: { (_, u) in validator(u) }, request: request)
    }
    
    func testEcho() throws {
        testSessionValue(Msg(msg: "Message")) { (msg: Msg) in msg.msg == "Message" }

        testSession(count: 100, validator: ==) { Msg(msg: "Message #\(arc4random())") }
    }

    func testStructure() throws {
//        let count = 2000 // about 31.518 secs
        let count = 5
        
        testSessionValue(count: count, StructureRequest(src: Src(identifier: "<FOO>", code: "case class Foo(i: Int)"))) { (resp: TreeResponse) in
            resp.tree.children.last?.symbol?.name == "Foo"
        }
        
        // 1000 takes about 12.197 seconds (about 66/second)
        testSession(count: count, validator: { (req: StructureRequest, resp: TreeResponse) in
            // tease the class name out of the request by looking for anything after the space and before the "{"
            let code = req.src.code
            let className = code.substring(to: code.range(of: "{")?.lowerBound ?? code.startIndex).substring(from: code.range(of: " ")?.lowerBound ?? code.startIndex).trimmingCharacters(in: CharacterSet.whitespaces)

//            dbg("looking for class: \(className) against \(resp.tree.children.last?.symbol?.name ?? "")")
            return resp.tree.children.last?.symbol?.name == className
        }) { StructureRequest(src: Src(identifier: "<FOO\(arc4random())>", code: "class Foo\(arc4random()) { val i\(arc4random()): Long = \(arc4random())L }\n")) }

//        func nodeType(_ node: ParseTree) -> String? {
//            return node.kind
////            switch node.kind {
////            case "scala.reflect.internal.Trees$ClassDef": return "class"
////            case "scala.reflect.internal.Trees$ModuleDef": return "object"
////            case "scala.reflect.internal.Trees$DefDef": return "def"
////            case "scala.reflect.internal.Trees$TypeDef": return "type"
////            default: return nil
////            }
//        }
        
        let extractionKinds: Set<KindFlag> = [.`class`, .object, .def, .type, .trait] // , .package, .`var`, .val]
        
        
        func extractSymbols(_ tree: ParseTree) -> [String] {
            var result: [String] = []
            func flatten(_ parent: String?, node: ParseTree) -> Void {
                var par = parent ?? ""

                if let type = node.kind, extractionKinds.contains(type) {
                    let flags = node.symbol?.flags ?? []
                    if let name = node.symbol?.name, !flags.contains(.Constructor), !flags.contains(.Private), !flags.contains(.Synthetic) {
                        result.append("(" + type.rawValue + ")" + par + name)
                        par += name + "."
                    }
                }
                let _ = node.children.flatMap({ child in flatten(par, node: child) })
            }
//            return flatten(tree).map { $0.symbol?.name ?? "" }
            
            flatten(.none, node: tree)
            return result
        }

        func checkSymbols(line: UInt = #line, _ code: String, symbols: [String]) {
            testSessionValue(line: line, StructureRequest(src: Src(identifier: "<testsrc\(line)>", code: code))) { (resp: TreeResponse) in
                let syms = extractSymbols(resp.tree)
                XCTAssertEqual(syms, symbols, "symbols did not match", line: line)
                return syms == symbols
            }
        }
        // many of these tests are taken straight from the ensime test cass
        
        if true { // "show top level classes and objects"
            let code = "" // package com.example\n" // FIXME
                + "" // import org.scalatest._\n"
                + "class Test {\n"
                + "    def fun(u: Int, v: Int) { u + v }\n"
                + "}\n"
                + "object Test {\n"
                + "    def apply(x: String) { new Test(x) }\n"
                + "}"
        
            let symbols: [String] = [
                "(class)Test",
                "(def)Test.fun",
                "(object)Test",
                "(def)Test.apply"
            ]
            
            checkSymbols(code, symbols: symbols)
        }
        
        
        if true { // "show nested members"
            let code = "package com.example\n"
                + "object Test {\n"
                + "    type TestType = Int\n"
                + "    class Nested {\n"
                + "        def fun(u: Int, v: Int) { u + v }\n"
                + "    }\n"
                + "    object Nested {\n"
                + "        def apply(x: String) { new Nested(x) }\n"
                + "    }\n"
                + "}"
            
            let symbols: [String] = [
                "(object)Test",
                "(type)Test.TestType",
                "(class)Test.Nested",
                "(def)Test.Nested.fun",
                "(object)Test.Nested",
                "(def)Test.Nested.apply"
            ]
            
            checkSymbols(code, symbols: symbols)
        }

        
        if true { // "skip accessors"
            let code = "class Test(val accessor: String)\n"
                + "class CaseTest(x: String, y: Int)\n"
                + "object Test {\n"
                + "    class Nested(val accessor: String)\n"
                + "    case class NestedCase(x: String, y:Int)\n"
                + "}"

  
            let symbols: [String] = [
                "(class)Test",
                "(class)CaseTest",
                "(object)Test",
                "(class)Test.Nested",
                "(class)Test.NestedCase",
            ]
            
            checkSymbols(code, symbols: symbols)
        }

    }

    
//    func testExample() throws {
//        do {
//            let session = try SparkSession();
//            let ctx = try KanjiScriptContext(engine: "scala")
//            let x = try ctx.val(ctx.eval("1"))
//            
//            XCTAssertEqual(2, x)
//        } catch {
//        print("#### error: \(error)")
//        }
////        XCTAssertEqual("3", try session.interpret("1 + 2"))
//        
//    }    
}
