//
//  ViewController.swift
//  Glint
//
//  Created by Marc Prud'hommeaux on 4/29/17.
//  Copyright © 2017 Glimpse I/O. All rights reserved.
//

import AppKit
import Glib
import Glue
import Glintette
import GlintModel

let defs = UserDefaults.standard

// defaults write io.glimpse.Glint GlintEditorFontSize -float 16
let fontSizePref = defs.float(forKey: "GlintEditorFontSize") > 0 ? defs.float(forKey: "GlintEditorFontSize") : 11.0
let fontFacePref = defs.string(forKey: "GlintEditorFontFace") ?? "Menlo" // Xcode is "SF Mono", but it isn't available: https://stackoverflow.com/questions/39890778/what-is-the-nsfont-name-for-the-font-sf-mono


// "DVTSourceTextSyntaxColors" in /Applications/Xcode.app/Contents/SharedFrameworks/DVTKit.framework/Versions/A/Resources/FontAndColorThemes/Basic.xccolortheme

struct SyntaxColors {
    static let attribute = colorPref(name: "attribute", def: "0 0 0 1")
    static let character = colorPref(name: "character", def: "0 0 0 1")
    static let comment = colorPref(name: "comment", def: "0 0.502 0 1")
    static let commentDoc = colorPref(name: "commentDoc", def: "0.0577329 0.43941 0.00537989 1")
    static let commentDocKeyword = colorPref(name: "commentDocKeyword", def: "0 0.502 0 1")
    static let identifierClass = colorPref(name: "identifierClass", def: "0.169 0.512 0.625 1")
    static let identifierClassSystem = colorPref(name: "identifierClassSystem", def: "0.169 0.512 0.625 1")
    static let identifierConstant = colorPref(name: "identifierConstant", def: "0.169 0.512 0.625 1")
    static let identifierConstantSystem = colorPref(name: "identifierConstantSystem", def: "0.169 0.512 0.625 1")
    static let identifierFunction = colorPref(name: "identifierFunction", def: "0.169 0.512 0.625 1")
    static let identifierFunctionSystem = colorPref(name: "identifierFunctionSystem", def: "0.169 0.512 0.625 1")
    static let identifierMacro = colorPref(name: "identifierMacro", def: "0 0 1 1")
    static let identifierMacroSystem = colorPref(name: "identifierMacroSystem", def: "0 0 1 1")
    static let identifierType = colorPref(name: "identifierType", def: "0.169 0.512 0.625 1")
    static let identifierTypeSystem = colorPref(name: "identifierTypeSystem", def: "0.169 0.512 0.625 1")
    static let identifierVariable = colorPref(name: "identifierVariable", def: "0.169 0.512 0.625 1")
    static let identifierVariableSystem = colorPref(name: "identifierVariableSystem", def: "0.169 0.512 0.625 1")
    static let keyword = colorPref(name: "keyword", def: "0 0 1 1")
    static let number = colorPref(name: "number", def: "0 0 0 1")
    static let plain = colorPref(name: "plain", def: "0 0 0 1")
    static let preprocessor = colorPref(name: "preprocessor", def: "0 0 1 1")
    static let string = colorPref(name: "string", def: "0.639 0.082 0.082 1")
    static let url = colorPref(name: "url", def: "0 0 1 1")
    
    private static func colorPref(name: String, def: String) -> NSColor {
        let str = defs.string(forKey: "GlintEditorSyntax\(name)") ?? def
        return NSColor(ciColor: CIColor(string: str))
    }
}


let session = GlintSession()

class ViewController: NSViewController {
    let split = NSSplitViewController()
    let editorController = EditorController()
    let outlineController = OutlineController()
    
    
    override func viewDidLoad() {
        dbg("setting up views")
        super.viewDidLoad()

        addChildViewController(split)
        self.view = split.view

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: outlineController)
        split.addSplitViewItem(sidebarItem)
        
        let detailItem = NSSplitViewItem(viewController: editorController)
        split.addSplitViewItem(detailItem)

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

class EditorController : NSViewController {
    let textView = NSTextView()

    override func loadView() {
        textView.font = NSFont(name: fontFacePref, size: CGFloat(fontSizePref))
        textView.delegate = self
        
        let textViewScroller = makeScroll(.vertical, document: textView)
        self.view = textViewScroller
    }
}

class OutlineController : NSViewController {
    let outlineView = NSOutlineView()

    override func loadView() {
//        outlineScroller.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
        outlineView.selectionHighlightStyle = .sourceList
        outlineView.headerView = nil
        
        let outlineViewScroller = makeScroll(.vertical, document: outlineView)
        self.view = outlineViewScroller
    }
}

extension EditorController : NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard let lm = textView.layoutManager else { return }
        let code = textView.string ?? ""
        let start = CFAbsoluteTimeGetCurrent()

        session.requestSyntax(code) { resp in
            let end = CFAbsoluteTimeGetCurrent()
            if let error = resp.error {
                dbg("error getting syntax: \(error)")
            } else if let tree = resp.value?.tree {
                dbg("syntax for \(bytestr(code)) in \(end - start) sec")
                DispatchQueue.main.async {
                    self.formatTree(lm, tree)
                }
            }
        }
    }
    
    func formatTree(_ lm: NSLayoutManager, _ tree: ParseTree) {
        
        func fmt(tree: ParseTree) {
            var color: NSColor = NSColor.textColor

            if let kind = tree.kind {
                switch kind {
                case .type: color = SyntaxColors.identifierType
                case .trait: color = SyntaxColors.identifierMacro
                case .`class`: color = SyntaxColors.identifierClass
                case .def: color = SyntaxColors.identifierFunction
                case .object: color = SyntaxColors.identifierClass
                case .package: color = SyntaxColors.identifierMacro
                case .`var`: color = SyntaxColors.identifierVariable
                case .val: color = SyntaxColors.identifierVariable
                }
            }
            
            if let start = tree.position.start, let end = tree.position.end, end > start {
                let range = NSRange(location: start, length: end - start)
//                dbg("highlighting \(start)-\(end): \(color.CSSColorHex()) kind: \(tree.kind) str: \(lm.textStorage!.string as NSString.substring(with: range))")
                lm.addTemporaryAttribute(NSForegroundColorAttributeName, value: color, forCharacterRange: range)
            }
            let _ = tree.children.map(fmt)
        }

        fmt(tree: tree)
    }
}

