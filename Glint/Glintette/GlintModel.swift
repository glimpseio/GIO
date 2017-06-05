//
//  GlintModel.swift
//  Glint
//
//  Created by Marc Prud'hommeaux on 5/24/17.
//  Copyright © 2017 Glimpse I/O. All rights reserved.
//

import Foundation
import BricBrac

public struct PresentError { let error: String }

extension PresentError : BricBrac {
    public func bric() -> Bric { return ["error": error.bric()] }
    public static func brac(bric: Bric) throws -> PresentError { return try PresentError(error: bric.brac(key: "error")) }
}

public struct Msg { let msg: String }

extension Msg : BricBrac {
    public func bric() -> Bric { return ["msg": msg.bric()] }
    public static func brac(bric: Bric) throws -> Msg { return try Msg(msg: bric.brac(key: "msg")) }
}

public enum KindFlag : String {
    case type
    case trait
    case `class`
    case def
    case object
    case package
    case `var`
    case val
}

extension KindFlag : BricBrac { }

public enum SymbolFlag : String {
    case `Type`
    case Term
    case Method
    case Constructor
    case Module
    case Class
    case ModuleClass
    case Synthetic
    case ImplementationArtifact
    case PrivateThis
    case Private
    case ProtectedThis
    case Protected
    case Public
    case PackageClass
    case Static
    case Final
    case Abstract
    case Macro
    case Parameter
    case Specialized
    case Java
    case Implicit
    //    case Term
    case Val
    case Stable
    case Var
    case Accessor
    case Getter
    case Setter
    case Overloaded
    case Lazy
    case ParamAccessor
    case CaseAccessor
    case ParamWithDefault
    case ByNameParam
    case Contravariant
    case isCovariant
    case AliasType
    case AbstractType
    case Existential
    //    case Method
    case PrimaryConstructor
    //    case Class
    case DerivedValueClass
    case Trait
    case CaseClass
    case Sealed
}

extension SymbolFlag : BricBrac { }

public struct Src { public var identifier: String, code: String }

public struct StructureRequest { public var src: Src }
public struct TreeResponse { public var desc: String, tree: ParseTree }

public struct ParseSymbol { public var name: String, flags: Set<SymbolFlag> }
public struct ParseType { public var name: String }
public struct ParsePosition { public var start: Optional<Int>, point: Optional<Int>, end: Optional<Int> }
public struct ParseTree { public var kind: KindFlag?, symbol: Optional<ParseSymbol>, `type`: Optional<ParseType>, position: ParsePosition, children: Array<ParseTree> }

extension Src : BricBrac {
    public func bric() -> Bric { return ["identifier": identifier.bric(), "code": code.bric()] }
    public static func brac(bric: Bric) throws -> Src { return try Src(identifier: bric.brac(key: "identifier"), code: bric.brac(key: "code")) }
}

extension StructureRequest : BricBrac {
    public func bric() -> Bric { return ["src": src.bric()] }
    public static func brac(bric: Bric) throws -> StructureRequest { return try StructureRequest(src: bric.brac(key: "src")) }
}

extension TreeResponse : BricBrac {
    public func bric() -> Bric { return ["desc": desc.bric(), "tree": tree.bric()] }
    public static func brac(bric: Bric) throws -> TreeResponse { return try TreeResponse(desc: bric.brac(key: "desc"), tree: bric.brac(key: "tree")) }
}

extension ParseSymbol : BricBrac {
    public func bric() -> Bric { return ["name": name.bric(), "flags": flags.bric()] }
    public static func brac(bric: Bric) throws -> ParseSymbol { return try ParseSymbol(name: bric.brac(key: "name"), flags: bric.brac(key: "flags")) }
}

extension ParseType : BricBrac {
    public func bric() -> Bric { return ["name": name.bric()] }
    public static func brac(bric: Bric) throws -> ParseType { return try ParseType(name: bric.brac(key: "name")) }
}

extension ParsePosition : BricBrac {
    public func bric() -> Bric { return ["start": start.bric(), "point": point.bric(), "end": end.bric()] }
    public static func brac(bric: Bric) throws -> ParsePosition { return try ParsePosition(start: bric.brac(key: "start"), point: bric.brac(key: "point"), end: bric.brac(key: "end")) }
}

extension ParseTree : BricBrac {
    public func bric() -> Bric { return ["kind": kind.bric(), "symbol": symbol.bric(), "type": `type`.bric(), "position": position.bric(), "children": children.bric()] }
    public static func brac(bric: Bric) throws -> ParseTree { return try ParseTree(kind: bric.brac(key: "kind"), symbol: bric.brac(key: "symbol"), type: bric.brac(key: "type"), position: bric.brac(key: "position"), children: bric.brac(key: "children")) }
}
