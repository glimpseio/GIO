//
//  SparkSession.swift
//  Glint
//
//  Created by Marc Prud'hommeaux on 4/29/17.
//  Copyright © 2017 Glimpse I/O. All rights reserved.
//
//
//import Foundation
//import Glib
//import BricBrac
//
//import KanjiScript
//import KanjiVM
//
//public class SparkSession {
//    
////    internal static override func initialize() {
////        let dir = "/opt/src/scala/scala-2.11.7/lib/"
////        let cp: [String] = (try? FileManager.default.contentsOfDirectory(atPath: dir).map({ dir + $0 })) ?? []
////        // needs to be boot; classpath scala beaks with: "Failed to initialize compiler: object scala in compiler mirror not found."
////        JVM.sharedJVM = try! JVM(bootpath: (cp, false))
////    }
//
//    private let ctx: KanjiScriptContext
//    private let repl: KanjiScriptContext.InstanceType
//    
//    public init() throws {
//        let dir = Bundle(for: SparkSession.self).url(forResource: "spark/spark-2.1.0-bin-hadoop2.7/jars", withExtension: "")!
//        let cp = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [])
//        assert(JVM.sharedJVM == nil, "JVM must not have been initialized")
//        JVM.sharedJVM = try JVM(classpath: cp.map({ $0.path }), options: ["-Dscala.usejavacp=true"])
//
//        ctx = try KanjiScriptContext(engine: "scala")
//
//        dbg("##### launched ctx: \(ctx)")
//        self.repl = try ctx.eval(.val(.str("scala.tools.nsc.interpreter.IMain()")))
//        
////        ctx = try KanjiScriptContext(engine: "js")
////        
////        // start up the repl
//////        let nm = try eval("Java.type('org.apache.spark.deploy.SparkSubmit').main(['--class', 'org.apache.spark.repl.Main', '--name', 'Spark shell'])")
////        self.repl = try ctx.eval(.val(.str("new (Java.type('scala.tools.nsc.interpreter.IMain'))()")))
////        try ctx.bind("repl", value: ctx.ref(repl))
//////        let _ = try ctx.eval(.val(.str("var settings = new (Java.type('scala.tools.nsc.Settings')); settings.usejavacp = true; repl.settings = settings;")))
//    }
//    
//    public func eval(_ code: String) throws -> String {
//        let bric = try ctx.eval(.val(.str(code)))
//        return bric.debugDescription
//    }
//    
//    public func interpret(_ code: String) throws -> String {
//        let val = try ctx.eval(.val(.str("repl.interpret('" + code + "')")))
//        return val.debugDescription
//    }
//
//}

