//
//  Vektorz.swift
//  Vektorz
//
//  Created by Marc Prud'hommeaux on 7/17/19.
//  Copyright © 2019 Glimpse I/O. All rights reserved.
//

import Foundation

public class SVGDocument : Hashable {
    let doc: CGSVGDocument

    public var canvasSize: CGSize {
        CGSVGDocumentGetCanvasSize(self.doc)
    }

    public var canvas: SVGCanvas {
        SVGCanvas(CGSVGDocumentGetCanvas(self.doc).takeUnretainedValue())
    }

    public var rootNode: SVGNode {
        SVGNode.create(CGSVGDocumentGetRootNode(self.doc).takeUnretainedValue())
    }

    public init(size: CGSize) {
        self.doc = CGSVGDocumentCreate(size).takeUnretainedValue()
        assert(CFGetTypeID(self.doc) == CGSVGDocumentTypeID)
    }

    public init?(data: Data, opts: SVGReaderOptions = 0) {
        guard let svgdoc = CGSVGDocumentCreateFromData(data as CFData, opts) else {
            return nil
        }
        self.doc = svgdoc.takeUnretainedValue()
        assert(CFGetTypeID(self.doc) == CGSVGDocumentTypeID)
    }

    deinit {
        // CGSVGDocumentRelease(self.doc)
    }

    func SVGData(options: SVGWriterOptions = 0) -> Data {
        let data = NSMutableData() as CFMutableData
        let _ = CGSVGDocumentWriteToData(self.doc, data, options)
        return data as Data
    }

    public func SVGString(options: SVGWriterOptions = 0) -> String {
        let trimHeader = "<!--Generator: [A-Za-z 0-9]*-->" // strip "Apple Native CoreSVG XYZ" header
        return (String(data: SVGData(options: options), encoding: .utf8) ?? "").replacingOccurrences(of: trimHeader, with: "", options: .regularExpression, range: nil)
    }

    public static func == (lhs: SVGDocument, rhs: SVGDocument) -> Bool {
        return CFEqual(lhs.doc, rhs.doc)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(self.doc))
    }

    public var description: String {
        return CFCopyDescription(self.doc) as String
    }
}

public class SVGCanvas : Hashable {
    let canvas: CGSVGCanvas

    init(_ canvasRef: CGSVGCanvas) {
        self.canvas = canvasRef
        assert(CFGetTypeID(self.canvas) == CGSVGCanvasTypeID)
    }

    public var currentGroup: SVGNode {
        SVGNode.create(CGSVGCanvasGetCurrentGroup(self.canvas).takeUnretainedValue())
    }

    @discardableResult
    public func pushGroup() -> SVGNode {
        SVGNode.create(CGSVGCanvasPushGroup(self.canvas).takeUnretainedValue())
    }

    @discardableResult
    public func popGroup() -> SVGNode {
        CGSVGCanvasPopGroup(self.canvas)
        return currentGroup
    }

    public func addRect(_ rect: CGRect) -> SVGNode {
        SVGNode.create(CGSVGCanvasAddRect(self.canvas, rect).takeUnretainedValue())
    }

    public func addEllipse(_ inRect: CGRect) -> SVGNode {
        SVGNode.create(CGSVGCanvasAddEllipseInRect(self.canvas, inRect).takeUnretainedValue())
    }

    public func addLine(from: CGPoint, to: CGPoint) -> SVGNode {
        SVGNode.create(CGSVGCanvasAddLine(self.canvas, from, to).takeUnretainedValue())
    }

    public func addPolyline(_ to: [CGPoint]) -> SVGNode {
        var floats: [CGFloat] = Array(to.map({ [$0.x, $0.y ]}).joined())
        return floats.withUnsafeMutableBufferPointer { ptr in
            return SVGNode.create(CGSVGCanvasAddPolyline(self.canvas, ptr.baseAddress, ptr.count).takeUnretainedValue())
        }
    }

    public func addPolygon(_ to: [CGPoint]) -> SVGNode {
        var floats: [CGFloat] = Array(to.map({ [$0.x, $0.y ]}).joined())
        return floats.withUnsafeMutableBufferPointer { ptr in
            return SVGNode.create(CGSVGCanvasAddPolygon(self.canvas, ptr.baseAddress, ptr.count).takeUnretainedValue())
        }
    }

    public func addPath(path: CGPath? = nil) -> SVGNode {
        if let path = path {
            return SVGNode.create(CGSVGCanvasAddPath(self.canvas, CGSVGPathCreateWithCGPath(path).takeUnretainedValue()).takeUnretainedValue())
        } else {
            return SVGNode.create(CGSVGCanvasAddPath(self.canvas, CGSVGPathCreate().takeUnretainedValue()).takeUnretainedValue())
        }
    }

    public static func == (lhs: SVGCanvas, rhs: SVGCanvas) -> Bool {
        return CFEqual(lhs.canvas, rhs.canvas)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(self.canvas))
    }

    public var description: String {
        return CFCopyDescription(self.canvas) as String
    }
}

public class SVGNode : Hashable {
    let node: CGSVGNode

    public enum NodeType : Int, Hashable {
        case root = 0
        case group = 1
        case shape = 2
        case unknown = -1
    }

    /// Creates a new node with the given `type`, or else creates a group node if the `type` is `nil`.
    public init(type: String? = nil) {
        if let type = type { // FIXME: crashes
            self.node = CGSVGNodeCreate(type as CFString).takeUnretainedValue()
        } else {
            self.node = CGSVGNodeCreateGroupNode().takeUnretainedValue()
        }

        assert(CFGetTypeID(self.node) == CGSVGNodeTypeID)
    }

    static func create(_ nodeRef: CGSVGNode) -> SVGNode {
        switch NodeType(rawValue: CGSVGNodeGetType(nodeRef)) {
        case .some(.root): return SVGRootNode(nodeRef)
        case .some(.shape): return SVGShapeNode(nodeRef)
        default: return SVGNode(nodeRef)
        }
    }

    fileprivate init(_ nodeRef: CGSVGNode) {
        self.node = nodeRef
        assert(CFGetTypeID(self.node) == CGSVGNodeTypeID)
    }

    public var nodeName: String {
        CGSVGNodeCopyName(self.node).takeUnretainedValue() as String
    }

    public var parent: SVGNode? {
        guard let parent = CGSVGNodeGetParent(self.node) else { return nil }
        return SVGNode.create(parent.takeUnretainedValue())
    }

    public var childCount: Int {
        CGSVGNodeGetChildCount(self.node)
    }

    public var nodeType: NodeType {
        return NodeType(rawValue: self.nodeTypeNumber) ?? .unknown
    }

    var nodeTypeNumber: Int {
        CGSVGNodeGetType(self.node)
    }

    public var attributes: SVGAttributeMap {
        get { SVGAttributeMap(map: CGSVGNodeGetAttributeMap(self.node).takeUnretainedValue()) }
        set { CGSVGNodeSetAttributeMap(self.node, newValue.attributeMap) }
    }

    public var stringIdentifier: String {
        CGSVGNodeCopyStringIdentifier(self.node).takeUnretainedValue() as String
    }

    public var text: String {
        CGSVGNodeCopyText(self.node).takeUnretainedValue() as String
    }

    public static func == (lhs: SVGNode, rhs: SVGNode) -> Bool {
        return CFEqual(lhs.node, rhs.node)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(self.node))
    }

    public var description: String {
        return CFCopyDescription(self.node) as String
    }
}

public class SVGRootNode : SVGNode {
//    private init() { // crashes
//        super.init(CGSVGRootNodeCreate().takeUnretainedValue())
//    }

    fileprivate override init(_ nodeRef: CGSVGNode) {
        super.init(nodeRef)
    }

    public var size: CGSize {
        get { CGSVGRootNodeGetSize(self.node) }
        set { CGSVGRootNodeSetSize(self.node, newValue) }
    }

    public var viewbox: CGRect {
        get { CGSVGRootNodeGetViewbox(self.node) }
        set { CGSVGRootNodeSetViewbox(self.node, newValue) }
    }

    public var aspectRatio: Int {
        get { CGSVGRootNodeGetAspectRatio(self.node) }
        set { CGSVGRootNodeSetAspectRatio(self.node, newValue) }
    }

}

public class SVGShapeNode : SVGNode {
//    private init() { // crashes
//        super.init(CGSVGShapeNodeCreate().takeUnretainedValue())
//    }

    fileprivate override init(_ nodeRef: CGSVGNode) {
        super.init(nodeRef)
    }

}

public class SVGAttribute : Hashable {
    let attr: CGSVGAttribute

    fileprivate init(attr: CGSVGAttribute) {
        self.attr = attr
//        assert(CFGetTypeID(self.attr) == CGSVGAttributeTypeID)
    }

    public var name: String {
        CGSVGAttributeGetName(self.attr).takeUnretainedValue() as String
    }

    public static func == (lhs: SVGAttribute, rhs: SVGAttribute) -> Bool {
        return CFEqual(lhs.attr, rhs.attr)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(self.attr))
    }

    public var description: String {
        return CFCopyDescription(self.attr) as String
    }
}

public final class SVGFloatAttribute : SVGAttribute {
    public convenience init(name: String, float: CGFloat) {

        // FIXME: Need to determine the correct attribute…
        self.init(attr: CGSVGAttributeCreateWithFloat(float, name as CFString).takeUnretainedValue())
    }

    public var value: CGFloat {
        CGSVGAttributeGetFloat(self.attr)
    }
}

public class SVGAttributeMap : Hashable {
    let attributeMap: CGSVGAttributeMap

    /// Creates a new node with the given `type`, or else creates a group node if the `type` is `nil`.
    public init() {
        self.attributeMap = CGSVGAttributeMapCreate().takeUnretainedValue()
        assert(CFGetTypeID(self.attributeMap) == CGSVGAttributeMapTypeID)
    }

    fileprivate init(map: CGSVGAttributeMap) {
        self.attributeMap = map
        assert(CFGetTypeID(self.attributeMap) == CGSVGAttributeMapTypeID)
    }

    subscript(name: String) -> SVGAttribute? {
        get {
            guard let attr = CGSVGAttributeMapGetAttribute(self.attributeMap, name as CFString) else {
                return nil
            }
            return SVGAttribute(attr: attr.takeUnretainedValue())
        }
    }

    public var count: Int {
        CGSVGAttributeMapGetCount(self.attributeMap)
    }

    public static func == (lhs: SVGAttributeMap, rhs: SVGAttributeMap) -> Bool {
        return CFEqual(lhs.attributeMap, rhs.attributeMap)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(self.attributeMap))
    }

    public var description: String {
        return CFCopyDescription(self.attributeMap) as String
    }
}

