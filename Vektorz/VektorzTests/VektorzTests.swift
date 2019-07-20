//
//  VektorzTests.swift
//  VektorzTests
//
//  Created by Marc Prud'hommeaux on 7/16/19.
//  Copyright © 2019 Glimpse I/O. All rights reserved.
//

import XCTest
@testable import Vektorz
//import CoreSVG


class VektorzTests: XCTestCase {
    func testSVGTypes() {
        do {
            let node = CGSVGNodeCreate("rect" as CFString)!.takeUnretainedValue()
            XCTAssertEqual(CGSVGNodeTypeID, CGSVGNodeGetTypeID(node))
        }

        do {
            let node = CGSVGNodeCreateGroupNode()!.takeUnretainedValue()
            XCTAssertEqual(CGSVGNodeTypeID, CGSVGNodeGetTypeID(node))
        }

    }

    func testCreateSVG() {
//        for _ in 1...100 {
//            createSVG()
//        }
//    }
//
//    func createSVG() {


        // FIXMEL crashes
//        do {
//            let fattr = SVGFloatAttribute(name: "foo", float: 1.2)
////            XCTAssertEqual(fattr.name, "foo")
//            XCTAssertEqual(fattr.value, 1.2)
//            return
//        }

//        do {
//            let atom = CGSVGAtomFromString("XYZ" as CFString)
//            XCTAssertEqual(CGSVGAtomCopyString(atom).takeUnretainedValue() as String, "XYZZ")
//        }
        
        let size = CGSize(width: 45, height: 30)
        let doc = SVGDocument(size: size)
        XCTAssertEqual(size, doc.canvasSize)

//        XCTAssertEqual(.shape, SVGRootNode().nodeType)
//        XCTAssertEqual(.shape, SVGShapeNode().nodeType)

        XCTAssertEqual(CGSVGDocumentTypeID, CGSVGDocumentGetTypeID(doc.doc))

        XCTAssertEqual(doc.SVGString(), """
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE svg
PUBLIC "-//W3C//DTD SVG 1.1//EN"
       "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="45" height="30"/>

""")

        let canvas = doc.canvas
        XCTAssertEqual("svg", doc.rootNode.nodeName)
        XCTAssertEqual("svg", canvas.currentGroup.nodeName)

        XCTAssertEqual(doc.rootNode, canvas.currentGroup)
        XCTAssertTrue(doc.rootNode is SVGRootNode)
        guard let rootNode = doc.rootNode as? SVGRootNode else {
            return XCTFail("rootNode \(doc.rootNode) was not a SVGRootNode")
        }

        XCTAssertEqual(CGRect.zero, rootNode.viewbox)
        XCTAssertEqual(size, rootNode.size)
        rootNode.size = CGSize(width: 250, height: 150)
        XCTAssertEqual(CGSize(width: 250, height: 150), rootNode.size)

        let viewbox = CGRect(x: 5, y: 5, width: 240, height: 140)
        rootNode.viewbox = viewbox
        XCTAssertEqual(viewbox, rootNode.viewbox)

        XCTAssertEqual(rootNode.aspectRatio, 5)
        XCTAssertEqual(5, rootNode.aspectRatio)
        rootNode.aspectRatio = 2
        XCTAssertEqual(rootNode.aspectRatio, 2)
        XCTAssertEqual(2, rootNode.aspectRatio)

        XCTAssertEqual(17, canvas.currentGroup.attributes.count)
        XCTAssertEqual(doc.rootNode, canvas.currentGroup)
        let g = canvas.pushGroup()
        XCTAssertNotEqual(doc.rootNode, canvas.currentGroup)
        XCTAssertEqual(0, canvas.currentGroup.attributes.count)

        XCTAssertEqual("g", g.nodeName)

        let g2 = canvas.pushGroup()
        XCTAssertEqual("g", g2.nodeName)
        XCTAssertEqual(.group, g2.nodeType)

        let rect = canvas.addRect(CGRect(x: 1, y: 2, width: 3, height: 4))
        XCTAssertEqual("rect", rect.nodeName)
        XCTAssertEqual(.shape, rect.nodeType)
        XCTAssertEqual("g", canvas.currentGroup.nodeName) // adding a rect does not change the group name

        XCTAssertEqual(rect.attributes, rect.attributes)

//        let rect = canvas.(CGRect(x: 1, y: 2, width: 3, height: 4))

        XCTAssertEqual(1, canvas.currentGroup.childCount)

        do {
            let node = canvas.addEllipse(CGRect(x: 1, y: 2, width: 3, height: 4))
            XCTAssertTrue(node is SVGShapeNode)
            XCTAssertEqual(.shape, node.nodeType)
            XCTAssertEqual("ellipse", node.nodeName)
            XCTAssertEqual(canvas.currentGroup, node.parent)
            XCTAssertNotEqual("", node.description)
            XCTAssertEqual(0, node.attributes.count)
        }

        XCTAssertEqual(2, canvas.currentGroup.childCount)

        do {
            let node = canvas.addLine(from: CGPoint(x: 11, y: 12), to: CGPoint(x: 123, y: 456))
            XCTAssertTrue(node is SVGShapeNode)
            XCTAssertEqual(.shape, node.nodeType)
            XCTAssertEqual("line", node.nodeName)
            XCTAssertEqual(canvas.currentGroup, node.parent)
            XCTAssertEqual(0, node.attributes.count)
        }

        XCTAssertEqual(3, canvas.currentGroup.childCount)

        do {
            let node = canvas.addPolyline([CGPoint(x: 101, y: 102), CGPoint(x: 201, y: 202)])
            XCTAssertTrue(node is SVGShapeNode)
            XCTAssertEqual(.shape, node.nodeType)
            XCTAssertEqual("polyline", node.nodeName)
            XCTAssertEqual(canvas.currentGroup, node.parent)
            XCTAssertEqual(1, node.attributes.count)
        }

        XCTAssertEqual(4, canvas.currentGroup.childCount)

        do {
            let node = canvas.addPolygon([CGPoint(x: 301, y: 302), CGPoint(x: 401, y: 402)])
            XCTAssertTrue(node is SVGShapeNode)
            XCTAssertEqual(.shape, node.nodeType)
            XCTAssertEqual("polygon", node.nodeName)
            XCTAssertEqual(canvas.currentGroup, node.parent)
            XCTAssertEqual(1, node.attributes.count)
//            XCTAssertEqual("XXX", node.attributes["XXX"]?.name)
//            XCTAssertEqual("XXX", node.attributes["points"]?.name)
        }

        XCTAssertEqual(5, canvas.currentGroup.childCount)

        do {
            do { canvas.pushGroup() }
            defer { canvas.popGroup() }

            let cgp = CGPath(roundedRect: CGRect(x: 10, y: 10, width: 20, height: 20), cornerWidth: 5, cornerHeight: 6, transform: nil)
            let node = canvas.addPath(path: cgp)
            XCTAssertTrue(node is SVGShapeNode)
            XCTAssertEqual(.shape, node.nodeType)
            XCTAssertEqual("path", node.nodeName)
            XCTAssertEqual(canvas.currentGroup, node.parent)
            XCTAssertEqual(1, node.attributes.count)
        }

        XCTAssertEqual(6, canvas.currentGroup.childCount)

        canvas.popGroup()
        XCTAssertEqual("g", canvas.currentGroup.nodeName)
        XCTAssertNotNil(canvas.currentGroup.parent)

        canvas.popGroup()
        XCTAssertEqual("svg", canvas.currentGroup.nodeName, "group should have popped back to the parent")
        XCTAssertNil(canvas.currentGroup.parent)

        canvas.popGroup() // no more popping
        XCTAssertEqual("svg", canvas.currentGroup.nodeName, "group should no pop past the root")

        XCTAssertEqual(.root, canvas.currentGroup.nodeType)

        // round-trip the document
        guard let doc2 = SVGDocument(data: doc.SVGData()) else {
            return XCTFail("unable to re-create document")
        }

        XCTAssertEqual(doc2.SVGString(), """
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE svg
PUBLIC "-//W3C//DTD SVG 1.1//EN"
       "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="250" height="150" viewBox="5 5 240 140">
 <g>
  <g>
   <rect height="4" width="3" x="1" y="2"/>
   <ellipse cx="2.5" cy="4" rx="1.5" ry="2"/>
   <line x1="11" x2="123" y1="12" y2="456"/>
   <polyline points="101 102 201 202"/>
   <polygon points="301 302 401 402"/>
   <g>
    <path d="M 30 20 L 30 24 C 30 27.3137 27.7614 30 25 30 L 15 30 C 12.2386 30 10 27.3137 10 24 L 10 16 C 10 12.6863 12.2386 10 15 10 L 25 10 C 27.7614 10 30 12.6863 30 16 Z"/>
   </g>
  </g>
 </g>
</svg>

""")

    }

    func XXXtestRenderSVG() {
        guard let samplesURL = Bundle(for: Self.self).url(forResource: "samples/svg", withExtension: "") else {
            return XCTFail("no samples folder")
        }

        guard let svgPaths = FileManager.default.enumerator(at: samplesURL, includingPropertiesForKeys: nil)?.compactMap({ $0 as? URL }).filter({ $0.pathExtension == "svg" }), !svgPaths.isEmpty else {
            return XCTFail("no svg samples")
        }

//        guard let imgclass = NSClassFromString("_NSSVGImageRep") else {
//            return XCTFail("no svg image rep")
//        }
//
//
//        print("imgclass", imgclass)
//
//        let svgrepcls = imgclass as! NSImageRep.Type
//        NSImageRep.registerClass(svgrepcls) // doesn't help for loading
//
//
//        print("all reps", NSImageRep.imageTypes)
//        //        print("png type", NSImageRep.class(forType: "png"))
//        print("png type", NSImageRep.class(forType: kUTTypePNG as String))
//        print("pdf type", NSImageRep.class(forType: kUTTypePDF as String))
//        print("svg type", NSImageRep.class(forType: kUTTypeScalableVectorGraphics as String))

        var errorRef: Unmanaged<CFError>?

        let readOptions = ["x": 1] as NSDictionary

        do {

            let badSVG = CGSVGDocumentCreateFromURL(NSURL(fileURLWithPath: "/tmp/DOESNOTEXIST.svg"), readOptions)
            XCTAssertNil(badSVG)
            // XCTAssertNotNil(errorRef?.takeRetainedValue().localizedDescription) // error doesn't seem to work…
        }

        var matched = 0 // the number of paths we matched

        for svgPath in svgPaths.shuffled() {

            print("rendering", svgPath)
//            print("reps", NSImageRep.imageReps(withContentsOf: svgPath))
//
//            let emptyimg = svgrepcls.init()
//            print("SVG", emptyimg, svgrepcls.canInit(with: try! svgPath.loadData()))

            guard let doc = CGSVGDocumentCreateFromURL(svgPath as NSURL, readOptions)?.takeRetainedValue() else {
                return XCTFail("unable to create document from \(svgPath)")
            }
            let canvasSize = CGSVGDocumentGetCanvasSize(doc)

            print("created document", doc, canvasSize)

            guard let root = CGSVGDocumentGetRootNode(doc)?.takeUnretainedValue() else {
                return XCTFail("no root node")
            }

            let rootID = CGSVGNodeCopyStringIdentifier(root)?.takeUnretainedValue() as NSString?
            let rootName = CGSVGNodeCopyName(root)?.takeUnretainedValue() as NSString?

            let rootCount = CGSVGNodeGetChildCount(root)
            print("root", root, "count", rootCount, "id", rootID as Any, "name", rootName as Any)

            func attributeString(node: CGSVGNode) -> String {
                let str = ""
//                guard let attrs = CGSVGNodeGetAttributeMap(node)?.takeUnretainedValue() else {
//                    return str
//                }
//
//                let count = CGSVGAttributeMapGetCount(attrs)
//                for i in 0..<count {
//                    guard let attr = CGSVGAttributeMapGetAttribute(attrs, i)?.takeUnretainedValue() else {
//                        continue
//                    }
//
//                    str += "\(attr)" // FIXME
//                    //                    guard let aname = CGSVGAttributeGetName(attr)?.takeUnretainedValue() else {
//                    //                        continue
//                    //                    }
//                    //                    str += "\(aname as String) "
//                }

                return str
            }

            func dumpNodes(node: CGSVGNode, indent: String) {
                let name = ((CGSVGNodeCopyName(node)?.takeUnretainedValue() as NSString?) as String?) ?? ""

                let box = CGSVGNodeGetBoundingBox(node)
                // let text = (CGSVGNodeCopyText(node)?.takeUnretainedValue() as NSString?) ?? ""

                print(indent + "<" + name + " \(box) \(attributeString(node: node))>")
                for i in 0..<CGSVGNodeGetChildCount(node) {
                    if let sub = CGSVGNodeGetChildAtIndex(node, i)?.takeUnretainedValue() {
                        dumpNodes(node: sub, indent: indent + "  ")
                        assert(CGSVGNodeGetParent(sub)?.takeUnretainedValue() === node) // make sure parent/child is correct
                    }
                }
                print(indent + "</" + name + ">")
            }

            dumpNodes(node: root, indent: "")

            XCTAssertEqual("svg", rootName, "the root node of all SVG documents must be \"svg\"")

            switch svgPath.lastPathComponent {
            case "Electromagnetic_Radiation_Spectrum_Infographic.svg":
                matched += 1
                XCTAssertEqual(CGSize(width: 4000, height: 4000), canvasSize)
                XCTAssertEqual(290, rootCount)
                XCTAssertEqual("", rootID)

            case "English_Wikipedia_Page_Views_Per_Country_2013_Q4.svg":
                matched += 1
                XCTAssertEqual(CGSize(width: 2754.0664, height: 1396.5739), canvasSize)
                XCTAssertEqual(249, rootCount)
                XCTAssertEqual("svg1926", rootID)

            case "Esparadrapo.svg":
                matched += 1
                XCTAssertEqual(CGSize(width: 461.74, height: 404.01), canvasSize)
                XCTAssertEqual(1, rootCount)
                XCTAssertEqual("", rootID)

            case "Fort_Delgrès,_plan.svg":
                matched += 1
                XCTAssertEqual(CGSize(width: 1059.9075, height: 698.84729), canvasSize)
                XCTAssertEqual(3, rootCount)
                XCTAssertEqual("svg2", rootID)

            case "How_a_Bill_Becomes_a_Law_Mike_Wirth_-_ru.svg":
                matched += 1
                XCTAssertEqual(CGSize(width: 3224.0754, height: 1590.4834), canvasSize)
                XCTAssertEqual(238, rootCount)
                XCTAssertEqual("Слой_1", rootID)

            case "Ryanscontribs.svg":
                matched += 1
                XCTAssertEqual(CGSize(width: 210.0, height: 204.0), canvasSize)
                XCTAssertEqual(1, rootCount)
                XCTAssertEqual("svg2211", rootID)

            default:
                break
            }

            //            continue // FIXME: cannot load image
            //
            //            guard let svgimg = svgrepcls.init(contentsOf: svgPath) else {
            //                return XCTFail("could not load svg \(svgPath)")
            //            }
            //
            ////            guard let img = NSImage(contentsOf: svgPath) else {
            ////                return XCTFail("could not load svg \(svgPath)")
            ////            }
            //            print("created image", svgimg)
        }

        XCTAssertEqual(6, matched, "not enough samples loaded")

    }
}

