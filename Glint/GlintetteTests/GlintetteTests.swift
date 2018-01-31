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
import GlintModel

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

    func XXXtestFormatting() throws {
        testSessionValue(FormatRequest(src: Src(identifier: "<FOO>", code: "  val x=2  "), params: FormatParams())) { (resp: FormatResponse) in
            resp.src.code == "val x = 2"
        }
    }
    
    
    func testMessages() throws {

        func checkMessages(line: UInt = #line, _ code: String, messages: Set<String>) {
            testSessionValue(line: line, TreeRequest(src: Src(identifier: "<testsrc\(line)>", code: code))) { (resp: TreeResponse) in
                let msgs = resp.infos.map { $0.msg }
                let contains = messages.isSubset(of: msgs)
                dbg(msgs)
                XCTAssertTrue(contains, "messages did not match", line: line)
                return contains
            }
        }

        // TODO: need to clear the logs between runs
        checkMessages("blahblah", messages: ["expected class or object definition"])
        checkMessages("val x = 1", messages: ["expected class or object definition"])
        checkMessages("object XXXYYY { }", messages: ["expected class or object definition"])
//        checkMessages("class FooFunc1 { def foofunc() : Unit = 1 }", messages: ["a pure expression does nothing in statement position; you may be omitting necessary parentheses"])
        checkMessages("class FooFunc2 { def x: String = 1 }", messages: ["type mismatch;\n found   : Int(1)\n required: String"])
    }

    func testPing() throws {
        
        func checkPings(line: UInt = #line, count: Int) {
            testSessionValue(line: line, PingRequest(interval: 0, limit: count)) { (resp: PingResponse) in
                XCTAssertEqual(resp.pong, 0)
                return resp.pong == 0
            }
        }

        checkPings(count: 1)
    }

    func testStructure() throws {
//        let count = 2000 // about 31.518 secs
        let count = 5
        
        testSessionValue(count: count, TreeRequest(src: Src(identifier: "<FOO>", code: "case class Foo(i: Int)"))) { (resp: TreeResponse) in
            resp.tree.children.last?.symbol?.name == "Foo"
        }
        
        // 1000 takes about 12.197 seconds (about 66/second)
        testSession(count: count, validator: { (req: TreeRequest, resp: TreeResponse) in
            // tease the class name out of the request by looking for anything after the space and before the "{"
            let code = req.src.code
            let className = code.substring(to: code.range(of: "{")?.lowerBound ?? code.startIndex).substring(from: code.range(of: " ")?.lowerBound ?? code.startIndex).trimmingCharacters(in: CharacterSet.whitespaces)

//            dbg("looking for class: \(className) against \(resp.tree.children.last?.symbol?.name ?? "")")
            return resp.tree.children.last?.symbol?.name == className
        }) { TreeRequest(src: Src(identifier: "<FOO\(arc4random())>", code: "class Foo\(arc4random()) { val i\(arc4random()): Long = \(arc4random())L }\n")) }
        
        let extractionKinds: Set<ParseTree.Kind> = [.class, .object, .def, .type, .trait] // , .package, .`var`, .val]
        
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
            testSessionValue(line: line, TreeRequest(src: Src(identifier: "<testsrc\(line)>", code: code))) { (resp: TreeResponse) in
                let syms = extractSymbols(resp.tree)
                XCTAssertEqual(syms, symbols, "symbols did not match", line: line)
                return syms == symbols
            }
        }
        
        // many of these tests are similar to ensime test cass
        
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

        
        if false { // "skip accessors"
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
    
    func testWebSocket() {
        let service = PresentURL + "ws-echo"
        let count = 200
        // we use a weird encoding on purpose to make sure the data blobs aren't sent at text
        let encoding = String.Encoding.utf32
        
        guard let url = URL(string: service) else {
            return XCTFail("bad url")
        }
        
        let expectations = (
            connected: expectation(description: "connection connected"),
            messages: expectation(description: "received all messages"),
            disconnected: expectation(description: "connection disconnected")
        )
        
        let socket = WebSocket(url: url)
        
        socket.onConnect = {
            expectations.connected.fulfill()
        }
        
        socket.onDisconnect = { (error: NSError?) in
            if error?.code != 1000 { // 1000 seems to happen on natural disconnect
                XCTAssertNil(error)
            }
            expectations.disconnected.fulfill()
        }
        
        socket.connect()
        wait(for: [expectations.connected], timeout: 10.0)
        
        // create a bunch of random messages to echo out over the socket
        var msgout = Array<String>()
        for _ in 1...count { msgout.append(NSUUID().uuidString) }
        
        var msgin: [String] = []
        
        // tests for receiving text
        socket.onText = { (text: String) in
            //            dbg("received string: \(text.characters.count)")
            msgin.append(text)
            if msgin.sorted() == msgout.sorted() {
                expectations.messages.fulfill()
            }
        }
        
        
        // tests for receiving data
        socket.onData = { (data: Data) in
            // dbg("received data: \(data.count)")
            if let text = String(data: data, encoding: encoding) {
                msgin.append(text)
            }
            if msgin.sorted() == msgout.sorted() {
                expectations.messages.fulfill()
            }
        }

        DispatchQueue.concurrentPerform(iterations: msgout.count, execute: { (index) in
            let msg = msgout[index]
            // test both sending of raw text and data
            if arc4random_uniform(10) > 5 {
                socket.write(string: msg)
            } else {
                socket.write(data: msg.data(using: encoding)!)
            }
        })
        
        wait(for: [expectations.messages], timeout: 10.0)
        XCTAssertEqual(msgin.sorted(), msgout.sorted())
        socket.disconnect()
        wait(for: [expectations.disconnected], timeout: 10.0)
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
