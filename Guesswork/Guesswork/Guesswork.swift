//
//  AppDelegate.swift
//  Guesswork
//
//  Created by Marc Prud'hommeaux on 1/24/18.
//  Copyright © 2018 Glimpse I/O. All rights reserved.
//

import AppKit
import Tiki
import Glib
import Glue
import ChannelZ
import WebKit
import KanjiVM
import KanjiLib
import KanjiScript
import BricBrac


@NSApplicationMain
final class AppDelegate: TriptychAppDelegate {
    static let start = NSDate()
    
    override init() {
        super.init()
        do {
            try TikiTorch.createJVM()
            dbg("activating: \(AppDelegate.start)")
        } catch {
            dbg("failed to load tiki: \(error)")
            
        }
    }
    
    /// Extend to add custom properties to the preferences pane controller
    override func setupAppPreferences(_ prefs: PreferencesPaneController) {
        super.setupAppPreferences(prefs)
        
        do {
            let pane = PreferencesTabController()
            pane.addPreferenceCheckbox(label: loc("Dark Window Appearance"), defaultsKey: \.darkAppearance, groupTitle: loc("Visual:"))
            pane.addPreferenceCheckbox(label: loc("Animated Transitions"), defaultsKey: \.animatedTransitions)
            prefs.addPreferencesTabController(pane, label: loc("General"), image: NSImage(named: .preferencesGeneral))
        }

        do {
            let pane = PreferencesTabController()
            pane.addPreferenceCheckbox(label: loc("Stuff"), defaultsKey: \.darkAppearance, groupTitle: loc("Group:"))
            pane.addPreferenceCheckbox(label: loc("More Stuff"), defaultsKey: \.darkAppearance)
            pane.addPreferenceCheckbox(label: loc("Some Other Stuff"), defaultsKey: \.darkAppearance)
            
            prefs.addPreferencesTabController(pane, label: loc("Users"), image: NSImage(named: .userAccounts))
        }
        
        do {
            let pane = PreferencesTabController()
            pane.addPreferenceCheckbox(label: loc("Stuff"), defaultsKey: \.darkAppearance, groupTitle: loc("Group:"))
            pane.addPreferenceCheckbox(label: loc("More Stuff"), defaultsKey: \.darkAppearance)
            pane.addPreferenceCheckbox(label: loc("Some More Stuff"), defaultsKey: \.darkAppearance, groupTitle: loc("A Really Long Group Title:"))
            for _ in 1...5 {
                pane.addPreferenceCheckbox(label: loc("Some Other Stuff"), defaultsKey: \.darkAppearance)
            }
            
            prefs.addPreferencesTabController(pane, label: loc("Advanced"), image: NSImage(named: .advanced))
        }

    }

    func applicationWillBecomeActive(_ notification: Notification) {
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // set up the standard defaults
        UserDefaults.standard.register(defaults: [
            UserDefaults.CustomKey.animatedTransitions.rawValue: true,
            UserDefaults.CustomKey.darkAppearance.rawValue: true,
            ])
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    func application(_ application: NSApplication, willPresentError error: Error) -> Error {
        dbg("presenting: \(error)")
        if let underlying = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error {
            dbg("  underlying: \(underlying)")
            if let kanjiError = underlying as? KanjiErrors {
                dbg("  kanjiError: \(kanjiError)")
            }
        }
        
        return error
    }
    
}

/// The document type for the app
final class Document: NSDocument {
    @objc dynamic var nodes: [TikiNode] = []
    
    override init() {
        super.init()
    }

    private func setupUndoSupport() {
    }

    override class var autosavesInPlace: Bool {
        return false
    }

    // example errors:
    // Caused by: java.lang.ClassNotFoundException: org.apache.poi.poifs.crypt.standard.StandardEncryptionInfoBuilder

    override open func willPresentError(_ error: Error) -> Error {
        dbg(error)
        return error
    }
    
    override open func willNotPresentError(_ error: Error) {
        dbg(error)
        return
    }
    
    override func makeWindowControllers() {
        let windowController = WindowController()
        self.addWindowController(windowController)
        assert(windowController.window != nil)
        setupUndoSupport()
    }
    
    override func read(from url: URL, ofType typeName: String) throws {
        let start = NSDate().timeIntervalSince1970
        let tiki = try TikiTorch()
        let meta = try tiki.extract(url: url, content: .xml)
        let node = try TikiNode(flattened: meta)
        self.nodes = [node] // node.children // these are the root nodes of the outline
        let end = NSDate().timeIntervalSince1970
        dbg("loaded metadata: \(meta.count) in \(end-start)")
    }
    
    override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
        return true // we can (and should) read from multiple threads
    }

    
//    override func printDocument(_ sender: Any?) {
//
//    }
//
//    @IBAction func print(_ sender: Any?) {
//
//    }
//

    /// The print operation merely delegates to the currently selected tab's webView
    override func printOperation(withSettings printSettings: [NSPrintInfo.AttributeKey : Any]) throws -> NSPrintOperation {
        for winc in self.windowControllers.flatMap({ $0 as? WindowController }) {
            let item = winc.mainControllerc.splitc.detailc.tabView.selectedTabViewItem
            if let controller = item?.viewController as? ContentPreviewBaseController {
                let webView = controller.webView
                let info = NSPrintInfo(dictionary: printSettings)
                return webView.mainFrame.frameView.printOperation(with: info)
            }
        }
        
        // delegate to the superclass (which will probably crash)
        return try super.printOperation(withSettings: printSettings)
    }

}

extension Document {
    /// Finds the TikiNodes at the given index paths
    func findNodes(at: [IndexPath]) -> [TikiNode] {
        return at.flatMap(findNode(indices:))
    }
    
    /// Finds the TikiNodes at the given index path
    func findNode(indices: IndexPath) -> TikiNode? {
        return indices.traverse(self.nodes, children: \.children)
    }
}

extension NSViewController {
    /// Returns the current WindowController for the given ViewController; may be .none if there is no current controller
    var winc: WindowController? { return self.view.window?.windowController as? WindowController }
    
    /// Returns the current Window's Document, if any
    var doc: Document? { return winc?.doc }
}

/// The WindowController associoated with the Document type
final class WindowController : TriptychWindowController<Document> {
    override lazy var mainController: TriptychMainController = mainControllerc
    lazy var mainControllerc = MainController()

    override func createWindow() -> NSWindow {
        let window = super.createWindow()

        window.contentMinSize = NSMakeSize(100, 100)
        
        // setup tabbing preference and dark appearance
        window.styleMask = [.closable, .resizable, .titled, .miniaturizable, .unifiedTitleAndToolbar]
        window.titleVisibility = .hidden
        window.tabbingMode = .preferred
        window.titlebarAppearsTransparent = true
        
        return window
    }
    
    open override func windowWillLoad() {
        super.windowWillLoad()
        dbg()
    }
    
    open override func windowDidLoad() {
        super.windowDidLoad()
        dbg()
    }
    
//    @IBAction override func togglePreferences(_ sender: AnyObject?) {
//        dbg("TODO: Override to show preferences pane")
//    }

}

final class MainController : TriptychMainController {
    override lazy var split = splitc as TriptychSplitController
    let splitc = cfg(SplitViewController()) { split in
    }
}

final class SplitViewController : TriptychSplitController {
    override lazy var outline: TriptychOutlineController = outlinec
    let outlinec = OutlineController()
    override lazy var detail: TriptychContentTabsController = detailc
    let detailc = ContentController()
    override lazy var inspector: TriptychInspectorController = inspectorc
    let inspectorc = DocumentInspectorController()
}

final class OutlineController : TriptychOutlineController, NSOutlineViewDelegate {
    lazy override var treeController = cfg(NSTreeController()) { treeController in
        treeController.childrenKeyPath = #keyPath(TikiNode.subnodes)
        treeController.leafKeyPath = #keyPath(TikiNode.isLeafNode)
    }

    /// "Document.nodes" – constructed since the "document" keyPath is an AnyObject?
    lazy override var contentArrayKeyPath: String? = #keyPath(WindowController.document) + "." + #keyPath(Document.nodes)
    
    override func loadView() {
        super.loadView()
        
        // custom bindings for cell-based view
//        outlineTableColumn.bind(.value, to: treeController, withKeyPath: "arrangedObjects.title", options: nil)
        
        outlineView.delegate = self
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        // item will be a NSTreeControllerTreeNode when using bindings
        
        guard let tableColumn = tableColumn else {
            return nil
        }
        
        let view = outlineView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView ?? cfg(makeOutlineTableCellView()) { view in
            // bind the associated TikiNode's title to the text field
            view.textField?.bind(.value, to: view, withKeyPath: "objectValue.title", options: nil)
            view.textField?.bind(.editable, to: view, withKeyPath: "objectValue.editable", options: nil)
            view.imageView?.bind(.image, to: view, withKeyPath: "objectValue.image", options: nil)
            //view.imageView?.bind(.alternateImage, to: view, withKeyPath: "objectValue.openImage", options: nil) // bummer: doesn't work
        }

//        dbg("view for item: \(item): \(view)")

        return view
    }
    
}

extension TikiNode {
    static let genericIcon = NSWorkspace.shared.icon(forFileType: NSFileTypeForHFSTypeCode(OSType(kGenericDocumentIcon)))
    static let genericFolderIcon = NSWorkspace.shared.icon(forFileType: NSFileTypeForHFSTypeCode(OSType(kGenericFolderIcon)))
    static let genericOpenFolderIcon = NSWorkspace.shared.icon(forFileType: NSFileTypeForHFSTypeCode(OSType(kOpenFolderIcon)))

    /// The image that will be displayed via the bindings for the outline cell via the "objectValue.image" binding
    @objc var image: NSImage? {
        // TODO: if this is a folder node and we have an unknown extension icon, then show a folder icon
        let fileIcon = NSWorkspace.shared.icon(forFileType: (title as NSString).pathExtension)
        if /* FIXME: not working: fileIcon == TikiNode.genericIcon && */ !children.isEmpty {
            // return the folder icon when the image is unknown and it is a folder
            // TODO: we could use kOpenFolderIcon for an open tree
            return TikiNode.genericFolderIcon
        }
        return fileIcon
    }

    /// The editable status of this node via the "objectValue.editable" binding
    @objc var editable: Bool {
        return false
    }
}

final class ContentController : TriptychContentTabsController, NSTextFinderClient {
    lazy var contentPreviewController = cfg(ContentPreviewController()) { controller in
    }
    lazy var contentPreviewControllerItem = cfg(NSTabViewItem(viewController: contentPreviewController)) { item in
        item.label = loc("Preview")
    }
    lazy var contentTextController = ContentTextController()
    lazy var contentTextControllerItem = cfg(NSTabViewItem(viewController: contentTextController)) { item in
        item.label = loc("Text")
    }

    override func viewDidLoad() {
        // must be done before calling super.viewDidLoad()
        addTabViewItem(contentTextControllerItem)
        addTabViewItem(contentPreviewControllerItem)
        super.viewDidLoad()
    }
}

//unowned(unsafe) open var uiDelegate: WebUIDelegate!
//unowned(unsafe) open var resourceLoadDelegate: WebResourceLoadDelegate!
//unowned(unsafe) open var downloadDelegate: WebDownloadDelegate!
//unowned(unsafe) open var frameLoadDelegate: WebFrameLoadDelegate!
//unowned(unsafe) open var policyDelegate: WebPolicyDelegate!

open class ContentPreviewBaseController : TriptychViewController, WebUIDelegate, WebResourceLoadDelegate, WebDownloadDelegate, WebFrameLoadDelegate, WebPolicyDelegate {
    let webView = cfg(WebView()) { webView in
        webView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).activate()
        webView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200).activate()
        webView.mainFrame.loadHTMLString(defaultHTML, baseURL: URL(fileURLWithPath: "file:///tmp"))
        webView.drawsBackground = true
        
        webView.preferences = guessworkWebPreferences
    }

    /// The current scroll position as a percentage of the document
    @objc dynamic var scrollPosition: Double = 0.0
    
    /// track the currently-loaded HTML so we don't unnecessarily reload a page when switching tabs
    public var currentHTML = ""
    
    open override func loadView() {
        self.view = webView
    }
    
    open override func viewDidAppear() {
        dbg(self)
        super.viewDidAppear()
        receipts += self.winc!.docZ.receive({ [weak self] doc in
            self?.renderSelection()
        }).makeIterator()
        
        receipts += self.winc!.channelZKeyValue(\.outlineSelection).receive({ [weak self] index in
//            dbg("select"selecion changed: \(index)")
            self?.renderSelection()
        }).makeIterator()
    }
    
    open override func viewDidDisappear() {
        dbg(self)
        super.viewDidDisappear()
        receipts.removeAll()
    }
    
    open func renderSelection() {
        dbg("TODO: override function to perform rendering")
    }
    
    open static override var restorableStateKeyPaths: [String] {
        // remember the scroll position in the current document
        return super.restorableStateKeyPaths + [
            #keyPath(scrollPosition),
        ]
    }
    
//    func performFindPanelAction(_ sender: Any?) {
//        dbg(sender)
//        webView.performFindPanelAction(sender)
//    }
}

final class ContentPreviewController : ContentPreviewBaseController {
    
    open override func renderSelection() {
        if let winc = winc, let doc = winc.document as? Document {
            let selection = doc.findNodes(at: winc.outlineSelection)
            renderNode(selection.first)
        }
    }

    open func renderNode(_ node: TikiNode?) {
        //dbg("inspecting node: \(node)")
        let content = node?[RecursiveTikaKeys.content]
        let html = content ?? defaultHTML
        dbg("loading document html size: \(ByteCountFormatter.string(fromByteCount: Int64(html.count), countStyle: ByteCountFormatter.CountStyle.file))")
        
        if html != currentHTML {
            currentHTML = html
            webView.mainFrame.loadHTMLString(currentHTML, baseURL: URL(fileURLWithPath: "file:///tmp"))
        }
    }
}

final class ContentTextController : ContentPreviewBaseController {
    open override func renderSelection() {
        if let winc = winc, let doc = winc.document as? Document {
            let selection = doc.findNodes(at: winc.outlineSelection)
            renderNode(selection.first)
        }
    }

    open func renderNode(_ node: TikiNode?) {
        //dbg("inspecting node: \(node)")
        let content = node?[RecursiveTikaKeys.content]
        let html = content ?? defaultHTML
        dbg("loading document html size: \(ByteCountFormatter.string(fromByteCount: Int64(html.count), countStyle: ByteCountFormatter.CountStyle.file))")
        
        if html != currentHTML {
            currentHTML = html
            webView.mainFrame.loadHTMLString(currentHTML, baseURL: URL(fileURLWithPath: "file:///tmp"))
        }
        
    }
}

final class DocumentInspectorController : TriptychInspectorController {
    override func viewDidAppear() {
        super.viewDidAppear()
        
        receipts += self.winc!.docZ.receive({ [weak self] doc in
            self?.renderSelection()
        }).makeIterator()
        
        receipts += self.winc!.channelZKeyValue(\.outlineSelection).receive({ [weak self] index in
//            dbg("selection changed: \(index)")
            self?.renderSelection()
        }).makeIterator()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        receipts.removeAll()
    }
    
    func renderSelection() {
        if let winc = winc, let doc = winc.document as? Document {
            let selection = doc.findNodes(at: winc.outlineSelection)
            updateInspectors(selection.first)
        }
    }
    
    func updateInspectors(_ node: TikiNode?) {
        var keyValues = node?.meta.obj ?? [:] // the remaining keys to analyze

        func addValueRows(_ value: Bric, transformer: (Bric) -> String?, title: String, controller: InspectorGroupController) {
            var wasTitled = false
            for val in (value.arr ?? [value]) { // some values like X-Parsed-By are arrays
                guard let stringValue = transformer(val) else { continue }
                let row = controller.recycle(TextFieldInspectorRowController.self, identifier: NSUserInterfaceItemIdentifier(title))
                if !wasTitled {
                    row.rowTitle = title // only the first item shows its title
                    wasTitled = true
                } else {
                    row.rowTitle = ""
                }
                
                row.binding.value = stringValue as NSString?
                row.editable = false
                
                controller.addRowController(row)
            }
        }

        func addGroup<T: MetadataKeys>(_ group: T.Type) {
            let id = NSUserInterfaceItemIdentifier(group.localizedGroupTitle)
            let igroup = recycleGroup(identifier: id, title: group.localizedGroupTitle)

            for key in group.allKeys {
                if let value = keyValues.removeValue(forKey: key.rawValue) {
                    if !key.isVisible { continue } // skip invisible keys, like X-TIKA:content
                    addValueRows(value, transformer: key.transformValue, title: key.localizedTitle, controller: igroup)
                }
            }
            
            if !igroup.visibleRows.isEmpty { // only add the group if it is not empty
                addGroupController(igroup)
            }
        }

        /// fill in the remaining keys in a misc group
        func addMiscGroup() {
            if !keyValues.isEmpty {
                let attrsGroup = recycleGroup(identifier: NSUserInterfaceItemIdentifier("Misc"), title: loc("Misc"))

                // try to pretty-up the keys a bit
                let keyInfo: [(String, String)] = keyValues.keys.sorted().map { k in
                    var pretty = k
                    let parts = pretty.split(separator: ":").filter({ !$0.isEmpty })
                    if !parts.isEmpty {
                        pretty = String(parts.last!)
                    }
                    
                    pretty = pretty.replace(string: "_", with: " ")
                    pretty = pretty.replace(string: "-", with: " ")
                    pretty = pretty.localizedCapitalized
                    return (k, pretty)
                    }.sorted { $0.1 < $1.1 }
                
                var seenKeyValues: [String: Bric] = [:]
                
                for (key, pretty) in keyInfo {
                    let value = keyValues[key]
                    // skip pretty keys that we have already seen
                    if value != nil && seenKeyValues[pretty] == value { continue }
                    seenKeyValues[pretty] = value
                    
                    if let value = value {
                        addValueRows(value, transformer: { $0.str }, title: pretty, controller: attrsGroup)
                    }
                }
                
                if !attrsGroup.visibleRows.isEmpty { // only add the group if it is not empty
                    addGroupController(attrsGroup)
                }
            }
        }
        
        //dbg("inspecting node: \(node)")
        let start = NSDate().timeIntervalSince1970
        self.clearInspectors(hide: true) // hide the current inspectors for later recycline

        addGroup(InvisibleKeys.self)
        addGroup(DublinCoreKeys.self)
        addGroup(OfficeKeys.self)
        addGroup(MessageKeys.self)
        addGroup(ImageKeys.self)
        addGroup(HTTPHeaderKeys.self)
        addGroup(TikaMetadataKeys.self)
        addGroup(RecursiveTikaKeys.self)
        addMiscGroup()
        
        self.alignLabels() // align all the labels in all the groups
        let end = NSDate().timeIntervalSince1970

        dbg("created \(groups.count) inspector groups (\(visibleGroups.count) visible) with \(groups.flatMap({ $0.rows }).count) rows (\(visibleGroups.flatMap({ $0.visibleRows }).count) visible) in \(end-start)")
        
    }
}


/// The default web preferences for GuessWork browsers
let guessworkWebPreferences = cfg(WebPreferences()) { prefs in
    prefs.isJavaEnabled = false
    prefs.isJavaScriptEnabled = false
    prefs.arePlugInsEnabled = false
    prefs.privateBrowsingEnabled = true
    
    prefs.userStyleSheetEnabled = true
    if let sheet = Bundle(for: ContentPreviewController.self).url(forResource: "GuessWorkDocument", withExtension: "css") {
        prefs.userStyleSheetLocation = sheet
    }
}

/// The default HTML that will be rendered when the document is empty
let defaultHTML = """
<html>

    <head>
        <title></title>
        <style>
        html, body {
        height: 100%;
        margin: 0;
        padding: 0;
        width: 100%;
        -webkit-user-select: none;
        user-select: none;
        -webkit-touch-callout: none;
        }

        body {
        display: table;
        }

        .centered-block {
        text-align: center;
        display: table-cell;
        vertical-align: middle;
        }
        </style>
    </head>

    <body>
        <div class="centered-block" style="font-family: HelveticaNeue-Light; font-size: 20pt; color: black; text-shadow: 2px 2px 3px rgba(100,100,100,0.1);">Drag File Here</div>
    </body>
</html>
"""

