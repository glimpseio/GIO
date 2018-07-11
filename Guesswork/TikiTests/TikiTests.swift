//
//  TikiTests.swift
//  TikiTests
//
//  Created by Marc Prud'hommeaux on 1/24/18.
//  Copyright © 2018 Glimpse I/O. All rights reserved.
//

import XCTest
@testable import Tiki
import BricBrac
import Glib
import KanjiVM
import KanjiLib
import JavaLib

class TikiTests: XCTestCase {
    
    func testSimpleExtract() throws {
        do {
            let tiki = try TikiTorch()
            XCTAssertEqual("Apache Tika 1.17", tiki.tikaDescription)
            
            let docSample = Bundle(for: TikiTests.self).url(forResource: "test", withExtension: "doc")!
            XCTAssertEqual("application/msword", try tiki.detect(url: docSample))
            XCTAssertEqual("test\n\n", try tiki.parseToString(url: docSample))
            
            var metadataX = try tiki.extract(url: docSample, content: .html, transferNative: false)
            var metadataY = try tiki.extract(url: docSample, content: .html, transferNative: true)
            XCTAssertEqual("Maxim Valyanskiy", metadataX.first?["Author"])
            XCTAssertEqual("application/msword", metadataY.first?["Content-Type"])
            
            // clear the parse times before asserting comparison
            metadataX[0]["X-TIKA:parse_time_millis"] = nil
            metadataY[0]["X-TIKA:parse_time_millis"] = nil
            
            XCTAssertEqual(metadataX, metadataY)
            
            dbg("got document: " + Bric.arr(metadataX).stringify(space: 2, maxline: 80))
        } catch {
            XCTFail("error: \(error)")
        }
    }

    func testEmbeddedExtract() throws {
        do {
            let tiki = try TikiTorch()
            
            let embedded = Bundle(for: TikiTests.self).url(forResource: "test_recursive_embedded", withExtension: "docx")!
            
            let metadata = try tiki.extract(url: embedded, content: .ignore, transferNative: true)

//            dbg("got document: " + Bric.arr(metadata).stringify(space: 2, maxline: 80))

            XCTAssertEqual(12, metadata.count)

            let ctypes = metadata.flatMap({ $0[HTTPHeaderKeys.CONTENT_TYPE.rawValue] })
            XCTAssertEqual(["application/vnd.openxmlformats-officedocument.wordprocessingml.document", "image/emf", "text/plain; charset=ISO-8859-1", "text/plain; charset=ISO-8859-1", "text/plain; charset=ISO-8859-1", "text/plain; charset=ISO-8859-1", "text/plain; charset=windows-1252", "text/plain; charset=ISO-8859-1", "application/zip", "application/zip", "application/zip", "application/zip"], ctypes)
            
            // the list of all the paths in the node
            let allPaths = ["/image1.emf", "/embed1.zip/embed1a.txt", "/embed1.zip/embed1b.txt", "/embed1.zip/embed2.zip/embed2a.txt", "/embed1.zip/embed2.zip/embed2b.txt", "/embed1.zip/embed2.zip/embed3.zip/embed3.txt", "/embed1.zip/embed2.zip/embed3.zip/embed4.zip/embed4.txt", "/embed1.zip/embed2.zip/embed3.zip/embed4.zip", "/embed1.zip/embed2.zip/embed3.zip", "/embed1.zip/embed2.zip", "/embed1.zip"]
            
            let respaths = metadata.flatMap({ $0[RecursiveTikaKeys.embedded_resource_path.rawValue] })
            XCTAssertEqual(allPaths, respaths.flatMap({ $0.str }))
            
            // now construct a TikiNode from the metadata
            let node = try TikiNode(flattened: metadata)
            
            XCTAssertEqual(node[DublinCoreKeys.modified], "2014-07-31T13:09:00Z")
            XCTAssertEqual(2, node.children.count)
            
            // make sure order is preserved
            XCTAssertEqual(["/image1.emf", "/embed1.zip"], node.children.flatMap({ $0[RecursiveTikaKeys.embedded_resource_path] }))
            
            // now ensure that the tree hierarchy is complete
            // note that we need to compare the sort values, since we can't preserve perfect hierarchical sortedness
            XCTAssertEqual(allPaths.sorted(), node.flatten().flatMap({ $0[RecursiveTikaKeys.embedded_resource_path] }).sorted())
        } catch {
            XCTFail("error: \(error)")
        }
    }
    
    func testTimeNativeExtract() throws {
        let tiki = try TikiTorch()
        let embedded = Bundle(for: TikiTests.self).url(forResource: "test_recursive_embedded", withExtension: "docx")!

        var metadata: [Bric]?
        measure { // avg: 0.196
            metadata = try? tiki.extract(url: embedded, content: .text, transferNative: true)
        }
        XCTAssertEqual(metadata?.count, 12)
    }

    func testTimeStringlyExtract() throws {
        let tiki = try TikiTorch()
        let embedded = Bundle(for: TikiTests.self).url(forResource: "test_recursive_embedded", withExtension: "docx")!
        
        var metadata: [Bric]?
        measure { // avg: 0.178
            metadata = try? tiki.extract(url: embedded, content: .text, transferNative: false)
        }
        XCTAssertEqual(metadata?.count, 12)
    }
    
    func testEncryptedDocuments() throws {
        let tiki = try TikiTorch()
        guard let doc = Bundle(for: TikiTests.self).url(forResource: "testAccess2_encrypted", withExtension: "accdb", subdirectory: "test-documents") else { return XCTFail("cound not load sample document") }
        
        do {
            let _ = try tiki.extract(url: doc, content: .ignore, transferNative: false)
        } catch let ex as KanjiException {
            XCTAssertNotNil(ex.message)
            XCTAssertEqual("java.lang.RuntimeException", ex.className)
            
            guard let rte = ex.asJavaException?.castTo(java$lang$RuntimeException.self) else {
                return XCTFail("wrong exception type: \(ex)")
            }
            
            guard let cause = try rte.getCause() else {
                return XCTFail("no cause: \(rte)")

            }
            
            XCTAssertEqual("org.apache.tika.exception.EncryptedDocumentException", try cause.getClass()?.getName())
        }

        // now try with the document password
        let _ = try tiki.extract(url: doc, content: .ignore, password: "tika")


    }

}
