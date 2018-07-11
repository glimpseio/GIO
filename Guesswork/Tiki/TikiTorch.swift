//
//  TikiTorch.swift
//  Tiki
//
//  Created by Marc Prud'hommeaux on 1/24/18.
//  Copyright © 2018 Glimpse I/O. All rights reserved.
//

import Foundation
import KanjiVM
import JavaLib
import KanjiLib
import KanjiScript
import BricBrac
import Glib

public final class TikiNode: NSObject {
    public let meta: Bric
    
    private(set) public var children: [TikiNode] = []

    public var content: String? { return meta[RecursiveTikaKeys.content.rawValue]?.str }
    
    public subscript<T: RawRepresentable>(tk: T) -> String? where T.RawValue == String { return meta[tk.rawValue]?.str }
//    public subscript(tk: TikaMetadataKeys) -> String? { return meta[tk.rawValue]?.str }
//    public subscript(rc: RecursiveTikaKeys) -> String? { return meta[rc.rawValue]?.str }
//    public subscript(dc: DublinCoreKeys) -> String? { return meta[dc.rawValue]?.str }
//    public subscript(ht: HTTPHeaderKeys) -> String? { return meta[ht.rawValue]?.str }

    /// Creates a node from a tree of metadata brics; note that the root node will be empty,
    /// since it may contain a child list of peers, so a single node metadata tree will
    /// still contain a single node with an child list of one element
    public convenience init(flattened: [Bric]) throws {
        guard let first = flattened.first else {
            throw err("empty metadata array")
        }
        
        self.init(meta: first)
        let nodes = Array(flattened.dropFirst(1)).map(TikiNode.init(meta:))
        
        // key the dictionary on the embedded path
        let resmap = Dictionary(uniqueKeysWithValues: nodes.map({ ($0[RecursiveTikaKeys.embedded_resource_path] ?? "", $0) }))
        
        // dbg("created resmap: \(resmap.keys)")
        
        // note that we do not sort the child list, since the order of the elements in the flattened
        // array may still be significant; instead we go from deepest parts to shallowest and add to the
        // children of the discovered parents; any orphaned nodes are assumed to live in the root
        let depths = nodes.map({ $0.resourceParts.count })

        for depth in Array(Set(depths)).sorted().reversed() {
            // get a list of the children at the given depth
            let depthNodes = nodes.filter({ $0.resourceParts.count == depth })
            for node in depthNodes {
                let parentPath = node.resourceParentPath
                if let parent = resmap[parentPath] {
                    //dbg("found parent in resmap: \(parentPath): \(parent)")
                    parent.children.append(node)
                } else {
                    //dbg("no parent in resmap: \(parentPath)")
                    self.children.append(node) // all nodes with no parents go into the root node
                }
            }
        }
    }
    
    public init(meta: Bric) {
        self.meta = meta
    }
    
    /// Returns a flattened array of all the children of this root node
    public func flatten() -> [TikiNode] {
        return children + children.flatMap({ $0.flatten() })
    }

    public var resourcePath: String? { return self[RecursiveTikaKeys.embedded_resource_path] }
    public var resourceParts: [String] { return Array((resourcePath ?? "").split(separator: "/")).map(String.init) }
    public var resourceParent: [String] {
        let parts = resourceParts
        return parts.isEmpty ? [] : Array(parts.dropLast())
    }
    
    public var resourceParentPath: String { return "/" + resourceParent.joined(separator: "/") }

    @objc public var title: String {
        return resourceParts.last ?? resourcePath ?? (self[TikaMetadataKeys.resourceName] as NSString?)?.lastPathComponent ?? loc("No Title")
    }
    
    /// Binding-compatible child array
    @objc public var subnodes: AnyObject? {
        return children as AnyObject?
    }
    
    @objc public var isLeafNode: Bool {
        return children.isEmpty
    }
}

public protocol MetadataKeys : RawRepresentable where Self.RawValue == String {
    /// The title for this metadata group
    static var localizedGroupTitle: String { get }
    
    /// All the keys in this metadata group
    static var allKeys: [Self] { get }
    
    /// The localized title for this key
    var localizedTitle: String { get }
    
    /// Whether this key should be visible for inspectors
    var isVisible: Bool { get }

    /// Transform this value for display, or return .none if it should be excluded
    func transformValue(_ value: Bric) -> String?
}

public extension MetadataKeys {
    var isVisible: Bool { return true }

    func transformValue(_ value: Bric) -> String? { return value.str }
}

//public enum XXXKeys : String {
//    case XXX = "XXX"
//}
//
//extension XXXKeys : MetadataKeys {
//    public static var localizedGroupTitle: String = loc("XXXX")
//
//    public static var allKeys: [XXXKeys] = [
//        .XXX,
//        ]
//
//    public var localizedTitle: String {
//        switch self {
//        case .XXX: return loc("XXX")
//        }
//    }
//}

/// From RecursiveParserWrapper
public enum RecursiveTikaKeys : String {
    case content = "X-TIKA:content"
    case parse_time_millis = "X-TIKA:parse_time_millis"
    case write_limit_reached = "X-TIKA:EXCEPTION:write_limit_reached"
    case embedded_resource_limit_reached = "X-TIKA:EXCEPTION:embedded_resource_limit_reached"
    case embedded_exception = "X-TIKA:EXCEPTION:embedded_exception"
    case embedded_resource_path = "X-TIKA:embedded_resource_path" // e.g.: "/embed1.zip/embed2.zip/embed3.zip/embed4.zip"
    case parsed_by = "X-Parsed-By"
}

extension RecursiveTikaKeys : MetadataKeys {
    public static var localizedGroupTitle: String = loc("Container")
    
    public static var allKeys: [RecursiveTikaKeys] = [.content, .parse_time_millis, .write_limit_reached, .embedded_resource_limit_reached, .embedded_exception, .embedded_resource_path, .parsed_by]
    
    public var localizedTitle: String {
        switch self {
        case .content: return loc("Content")
        case .parse_time_millis: return loc("Parse Time")
        case .write_limit_reached: return loc("Write Limit")
        case .embedded_resource_limit_reached: return loc("Resource Limit")
        case .embedded_exception: return loc("Error")
        case .embedded_resource_path: return loc("Resource Path")
        case .parsed_by: return loc("Parser")
        }
    }
    
    public var isVisible: Bool {
        switch self {
        case .content: return false
        case .parse_time_millis: return false
        default: return true
        }
    }
    
    public func transformValue(_ value: Bric) -> String? {
        switch self {
        // parsed_by is an array of class names; just show the last part of the list
        case .parsed_by: return value.str?.split(separator: ".").last.map(String.init)
        default: return value.str
        }
    }

}

public enum TikaMetadataKeys : String {
    case resourceName = "resourceName"
    case protected = "protected"
    case embeddedRelationshipId = "embeddedRelationshipId" // e.g.: "embed3/embed4.zip"
    case embeddedStorageClassId = "embeddedStorageClassId"
    case embeddedResourceType = "embeddedResourceType"
}

extension TikaMetadataKeys : MetadataKeys {
    public static var localizedGroupTitle: String = loc("Embedded Content")
    
    public static var allKeys: [TikaMetadataKeys] = [.resourceName, .protected, .embeddedRelationshipId, .embeddedStorageClassId, .embeddedResourceType]
    
    public var localizedTitle: String {
        switch self {
        case .resourceName: return loc("Resource Name")
        case .protected: return loc("Protected")
        case .embeddedRelationshipId: return loc("Relation ID")
        case .embeddedStorageClassId: return loc("Storage Class")
        case .embeddedResourceType: return loc("Resource Type")
        }
    }
}

/// These don't seem to be formally defined, but I found them in ImageParserTest.java; seems to be mostly from IIOMetadata
public enum ImageKeys : String {
    case width = "width"
    case height = "height"
    
    case compressionLossless = "Compression Lossless"
    case compressionTypeName = "Compression CompressionTypeName"
    case compressionNumProgressiveScans = "Compression NumProgressiveScans"

    case dimensionImageOrientation = "Dimension ImageOrientation"
    case dimensionPixelAspectRatio = "Dimension PixelAspectRatio"
    case dimensionVerticalPixelOffset = "Dimension VerticalPixelOffset"
    case dimensionVerticalPixelSize = "Dimension VerticalPixelSize"
    case dimensionVerticalPhysicalPixelSpacing = "Dimension VerticalPhysicalPixelSpacing"
    case dimensionHorizontalPixelOffset = "Dimension HorizontalPixelOffset"
    case dimensionHorizontalPixelSize = "Dimension HorizontalPixelSize"
    case dimensionHorizontalPhysicalPixelSpacing = "Dimension HorizontalPhysicalPixelSpacing"
    
    case transparencyAlpha = "Transparency Alpha"
    
    case chromaNumChannels = "Chroma NumChannels"
    case chromaColorSpaceType = "Chroma ColorSpaceType"
    case chromaBlackIsZero = "Chroma BlackIsZero"

    case dataSampleFormat = "Data SampleFormat"
    case dataBitsPerSample = "Data BitsPerSample"
    case dataPlanarConfiguration = "Data PlanarConfiguration"

    case imageDescriptor = "ImageDescriptor"
    case commentExtensionsCommentExtension = "CommentExtensions CommentExtension"
    case textTextEntry = "Text TextEntry"
    case graphicControlExtension = "GraphicControlExtension"
    case IHDR = "IHDR"
    case documentImageModificationTime = "Document ImageModificationTime"
}

extension ImageKeys : MetadataKeys {
    public static var localizedGroupTitle: String = loc("Image")
    
    public static var allKeys: [ImageKeys] = [
        .width,
        .height,

        .compressionLossless,
        .compressionTypeName,
        .compressionNumProgressiveScans,
        
        .dimensionImageOrientation,
        .dimensionPixelAspectRatio,
        .dimensionVerticalPixelOffset,
        .dimensionVerticalPixelSize,
        .dimensionVerticalPhysicalPixelSpacing,
        .dimensionHorizontalPixelOffset,
        .dimensionHorizontalPixelSize,
        .dimensionHorizontalPhysicalPixelSpacing,
        
        .transparencyAlpha,
        
        .chromaColorSpaceType,
        .chromaNumChannels,
        .chromaBlackIsZero,

        .dataSampleFormat,
        .dataBitsPerSample,
        .dataPlanarConfiguration,

        .imageDescriptor,
        .compressionNumProgressiveScans,
        .commentExtensionsCommentExtension,
        .textTextEntry,
        .graphicControlExtension,
        .IHDR,
        .documentImageModificationTime,
        
        ]
    
    public var localizedTitle: String {
        switch self {
        case .width: return loc("Width")
        case .height: return loc("Height")
            
        case .compressionLossless: return loc("Lossless")
        case .compressionTypeName: return loc("Compression Type")
        case .compressionNumProgressiveScans: return loc("Progressive Scans")
            
        case .dimensionImageOrientation: return loc("Image Orientation")
        case .dimensionPixelAspectRatio: return loc("Pixel Aspect Ratio")
        case .dimensionVerticalPixelOffset: return loc("V Pixel Offset")
        case .dimensionVerticalPixelSize: return loc("V Pixel Size")
        case .dimensionVerticalPhysicalPixelSpacing: return loc("V Pixel Spacing")
        case .dimensionHorizontalPixelOffset: return loc("H Pixel Offset")
        case .dimensionHorizontalPixelSize: return loc("H Pixel Size")
        case .dimensionHorizontalPhysicalPixelSpacing: return loc("H Pixel Spacing")
            
        case .transparencyAlpha: return loc("Transparency Alpha")
            
        case .chromaNumChannels: return loc("Chroma Channels")
        case .chromaColorSpaceType: return loc("Chroma Color Space Type")
        case .chromaBlackIsZero: return loc("Chroma Black Zero")
            
        case .dataSampleFormat: return loc("Data Sample Format")
        case .dataBitsPerSample: return loc("Data Bits per Sample")
        case .dataPlanarConfiguration: return loc("Data Planar Configuration")
            
        case .imageDescriptor: return loc("Image Descriptor")
        case .commentExtensionsCommentExtension: return loc("Comments")
        case .textTextEntry: return loc("Text")
        case .graphicControlExtension: return loc("Graphic Control Extension")
        case .IHDR: return loc("IHDR")
        case .documentImageModificationTime: return loc("Image Modification Time")
        }
    }
}

public enum HTTPHeaderKeys : String {
    case CONTENT_ENCODING = "Content-Encoding"
    case CONTENT_LANGUAGE = "Content-Language"
    case CONTENT_LENGTH = "Content-Length"
    case CONTENT_LOCATION = "Content-Location"
    case CONTENT_DISPOSITION = "Content-Disposition"
    case CONTENT_MD5 = "Content-MD5"
    case CONTENT_TYPE = "Content-Type"
    case LAST_MODIFIED = "Last-Modified"
    case LOCATION = "Location"
}

extension HTTPHeaderKeys : MetadataKeys {
    public static var localizedGroupTitle: String = loc("Content")
    
    public static var allKeys: [HTTPHeaderKeys] = [.CONTENT_ENCODING, .CONTENT_LANGUAGE, .CONTENT_LENGTH, .CONTENT_LOCATION, .CONTENT_DISPOSITION, .CONTENT_MD5, .CONTENT_TYPE, .LAST_MODIFIED, .LOCATION]
    
    public var localizedTitle: String {
        switch self {
        case .CONTENT_ENCODING: return loc("Encoding")
        case .CONTENT_LANGUAGE: return loc("Language")
        case .CONTENT_LENGTH: return loc("Length")
        case .CONTENT_LOCATION: return loc("Location")
        case .CONTENT_DISPOSITION: return loc("Disposition")
        case .CONTENT_MD5: return loc("Checksum")
        case .CONTENT_TYPE: return loc("Type")
        case .LAST_MODIFIED: return loc("Modified")
        case .LOCATION: return loc("Location")
        }
    }
}

public enum OfficeKeys : String {
    case INITIAL_AUTHOR = "meta:initial-author"
    case LAST_AUTHOR = "meta:last-author"
    case AUTHOR = "meta:author"
    case CREATION_DATE = "meta:creation-date"
    case SAVE_DATE = "meta:save-date"
    case PRINT_DATE = "meta:print-date"
    case SLIDE_COUNT = "meta:slide-count"
    case PAGE_COUNT = "meta:page-count"
    case PARAGRAPH_COUNT = "meta:paragraph-count"
    case LINE_COUNT = "meta:line-count"
    case WORD_COUNT = "meta:word-count"
    case CHARACTER_COUNT = "meta:character-count"
    case CHARACTER_COUNT_WITH_SPACES = "meta:character-count-with-spaces"
    case TABLE_COUNT = "meta:table-count"
    case IMAGE_COUNT = "meta:image-count"
    case OBJECT_COUNT = "meta:object-count"
    case MAPI_MESSAGE_CLASS = "meta:mapi-message-class"
    case MAPI_SENT_BY_SERVER_TYPE = "meta:mapi-sent-by-server-type"
    case MAPI_FROM_REPRESENTING_NAME = "meta:mapi-from-representing-name"
    case MAPI_FROM_REPRESENTING_EMAIL = "meta:mapi-from-representing-email"
    case KEYWORDS = "meta:keyword"
}

extension OfficeKeys : MetadataKeys {
    public static var localizedGroupTitle: String = loc("Document")
    
    public static var allKeys: [OfficeKeys] = [
        .INITIAL_AUTHOR, .LAST_AUTHOR, .AUTHOR, .CREATION_DATE, .SAVE_DATE, .PRINT_DATE, .SLIDE_COUNT, .PAGE_COUNT, .PARAGRAPH_COUNT, .LINE_COUNT, .WORD_COUNT, .CHARACTER_COUNT, .CHARACTER_COUNT_WITH_SPACES, .TABLE_COUNT, .IMAGE_COUNT, .OBJECT_COUNT, .MAPI_MESSAGE_CLASS, .MAPI_SENT_BY_SERVER_TYPE, .MAPI_FROM_REPRESENTING_NAME, .MAPI_FROM_REPRESENTING_EMAIL, .KEYWORDS]
    
    public var localizedTitle: String {
        switch self {
        case .KEYWORDS: return loc("Keywords")
        case .INITIAL_AUTHOR: return loc("Initial Author")
        case .LAST_AUTHOR: return loc("Last Author")
        case .AUTHOR: return loc("Author")
        case .CREATION_DATE: return loc("Creation Date")
        case .SAVE_DATE: return loc("Save Date")
        case .PRINT_DATE: return loc("Print Date")
        case .SLIDE_COUNT: return loc("Slide Count")
        case .PAGE_COUNT: return loc("Page Count")
        case .PARAGRAPH_COUNT: return loc("Paragraph Count")
        case .LINE_COUNT: return loc("Line Count")
        case .WORD_COUNT: return loc("Word Count")
        case .CHARACTER_COUNT: return loc("Character Count")
        case .CHARACTER_COUNT_WITH_SPACES: return loc("All Character Count")
        case .TABLE_COUNT: return loc("Table Count")
        case .IMAGE_COUNT: return loc("Image Count")
        case .OBJECT_COUNT: return loc("Object Count")
        case .MAPI_MESSAGE_CLASS: return loc("Message Class")
        case .MAPI_SENT_BY_SERVER_TYPE: return loc("Sent Server Type")
        case .MAPI_FROM_REPRESENTING_NAME: return loc("From Name")
        case .MAPI_FROM_REPRESENTING_EMAIL: return loc("From Email")
        }
    }
}

public enum MessageKeys : String {
    case MESSAGE_RECIPIENT_ADDRESS = "Message-Recipient-Address"
    case MESSAGE_FROM = "Message-From"
    case MESSAGE_TO = "Message-To"
    case MESSAGE_CC = "Message-Cc"
    case MESSAGE_BCC = "Message-Bcc"
    case MULTIPART_SUBTYPE = "Multipart-Subtype"
    case MULTIPART_BOUNDARY = "Multipart-Boundary"
    case MESSAGE_FROM_NAME = "Message:From-Name"
    case MESSAGE_FROM_EMAIL = "Message:From-Email"
    case MESSAGE_TO_NAME = "Message:To-Name"
    case MESSAGE_TO_DISPLAY_NAME = "Message:To-Display-Name"
    case MESSAGE_TO_EMAIL = "Message:To-Email"
    case MESSAGE_CC_NAME = "Message:CC-Name"
    case MESSAGE_CC_DISPLAY_NAME = "Message:CC-Display-Name"
    case MESSAGE_CC_EMAIL = "Message:CC-Email"
    case MESSAGE_BCC_NAME = "Message:BCC-Name"
    case MESSAGE_BCC_DISPLAY_NAME = "Message:BCC-Display-Name"
    case MESSAGE_BCC_EMAIL = "Message:BCC-Email"
}

extension MessageKeys : MetadataKeys {
    public static var localizedGroupTitle: String = loc("Message")
    
    public static var allKeys: [MessageKeys] = [.MESSAGE_RECIPIENT_ADDRESS, .MESSAGE_FROM, .MESSAGE_TO, .MESSAGE_CC, .MESSAGE_BCC, .MULTIPART_SUBTYPE, .MULTIPART_BOUNDARY, .MESSAGE_FROM_NAME, .MESSAGE_FROM_EMAIL, .MESSAGE_TO_NAME, .MESSAGE_TO_DISPLAY_NAME, .MESSAGE_TO_EMAIL, .MESSAGE_CC_NAME, .MESSAGE_CC_DISPLAY_NAME, .MESSAGE_CC_EMAIL, .MESSAGE_BCC_NAME, .MESSAGE_BCC_DISPLAY_NAME, .MESSAGE_BCC_EMAIL]
    
    public var localizedTitle: String {
        switch self {
        case .MESSAGE_RECIPIENT_ADDRESS: return loc("Recipient")
        case .MESSAGE_FROM: return loc("From")
        case .MESSAGE_TO: return loc("To")
        case .MESSAGE_CC: return loc("Cc")
        case .MESSAGE_BCC: return loc("Bcc")
        case .MULTIPART_SUBTYPE: return loc("Subtype")
        case .MULTIPART_BOUNDARY: return loc("Boundary")
        case .MESSAGE_FROM_NAME: return loc("From Name")
        case .MESSAGE_FROM_EMAIL: return loc("From Email")
        case .MESSAGE_TO_NAME: return loc("To Name")
        case .MESSAGE_TO_DISPLAY_NAME: return loc("To Display Name")
        case .MESSAGE_TO_EMAIL: return loc("To Email")
        case .MESSAGE_CC_NAME: return loc("CC Name")
        case .MESSAGE_CC_DISPLAY_NAME: return loc("CC Display Name")
        case .MESSAGE_CC_EMAIL: return loc("CC Email")
        case .MESSAGE_BCC_NAME: return loc("BCC Name")
        case .MESSAGE_BCC_DISPLAY_NAME: return loc("BCC Display Name")
        case .MESSAGE_BCC_EMAIL: return loc("BCC Email")
        }
    }
    
}

public enum DublinCoreKeys : String {
    /// Typically, Format may include the media-type or dimensions of the
    /// resource. Format may be used to determine the software, hardware or
    /// other equipment needed to display or operate the resource. Examples
    /// of dimensions include size and duration. Recommended best practice is
    /// to select a value from a controlled vocabulary (for example, the list
    /// of Internet Media Types [MIME] defining computer media formats).
    case format = "dc:format"
    
    /// Recommended best practice is to identify the resource by means of
    /// a string or number conforming to a formal identification system.
    /// Example formal identification systems include the Uniform Resource
    /// Identifier (URI) (including the Uniform Resource Locator (URL)),
    /// the Digital Object Identifier (DOI) and the International Standard
    /// Book Number (ISBN).
    case identifier = "dc:identifier"
    
    /// Date on which the resource was changed.
    case modified = "dcterms:modified"
    
    /// An entity responsible for making contributions to the content of the
    /// resource. Examples of a Contributor include a person, an organisation,
    /// or a service. Typically, the name of a Contributor should be used to
    /// indicate the entity.
    case contributor = "dc:contributor"
    
    /// The extent or scope of the content of the resource. Coverage will
    /// typically include spatial location (a place name or geographic
    /// coordinates), temporal period (a period label, date, or date range)
    /// or jurisdiction (such as a named administrative entity). Recommended
    /// best practice is to select a value from a controlled vocabulary (for
    /// example, the Thesaurus of Geographic Names [TGN]) and that, where
    /// appropriate, named places or time periods be used in preference to
    /// numeric identifiers such as sets of coordinates or date ranges.
    case coverage = "dc:coverage"
    
    /// An entity primarily responsible for making the content of the resource.
    /// Examples of a Creator include a person, an organisation, or a service.
    /// Typically, the name of a Creator should be used to indicate the entity.
    case creator = "dc:creator"
    
    /// Date of creation of the resource.
    case created = "dcterms:created"
    
    /// A date associated with an event in the life cycle of the resource.
    /// Typically, Date will be associated with the creation or availability of
    /// the resource. Recommended best practice for encoding the date value is
    /// defined in a profile of ISO 8601 [W3CDTF] and follows the YYYY-MM-DD
    /// format.
    case date = "dc:date"
    
    /// An account of the content of the resource. Description may include
    /// but is not limited to: an abstract, table of contents, reference to
    /// a graphical representation of content or a free-text account of
    /// the content.
    case description = "dc:description"
    
    /// A language of the intellectual content of the resource. Recommended
    /// best practice is to use RFC 3066 [RFC3066], which, in conjunction
    /// with ISO 639 [ISO639], defines two- and three-letter primary language
    /// tags with optional subtags. Examples include "en" or "eng" for English,
    /// "akk" for Akkadian, and "en-GB" for English used in the United Kingdom.
    case language = "dc:language"
    
    /// An entity responsible for making the resource available. Examples of
    /// a Publisher include a person, an organisation, or a service. Typically,
    /// the name of a Publisher should be used to indicate the entity.
    case publisher = "dc:publisher"
    
    /// A reference to a related resource. Recommended best practice is to
    /// reference the resource by means of a string or number conforming to
    /// a formal identification system.
    case relation = "dc:relation"
    
    /// Information about rights held in and over the resource. Typically,
    /// a Rights element will contain a rights management statement for
    /// the resource, or reference a service providing such information.
    /// Rights information often encompasses Intellectual Property Rights
    /// (IPR), Copyright, and various Property Rights. If the Rights element
    /// is absent, no assumptions can be made about the status of these and
    /// other rights with respect to the resource.
    case rights = "dc:rights"
    
    /// A reference to a resource from which the present resource is derived.
    /// The present resource may be derived from the Source resource in whole
    /// or in part. Recommended best practice is to reference the resource by
    /// means of a string or number conforming to a formal identification
    /// system.
    case source = "dc:source"
    
    /// The topic of the content of the resource. Typically, a Subject will
    /// be expressed as keywords, key phrases or classification codes that
    /// describe a topic of the resource. Recommended best practice is to
    /// select a value from a controlled vocabulary or formal classification
    /// scheme.
    case subject = "dc:subject"
    
    /// A name given to the resource. Typically, a Title will be a name by
    /// which the resource is formally known.
    case title = "dc:title"
    
    /// The nature or genre of the content of the resource. Type includes terms
    /// describing general categories, functions, genres, or aggregation levels
    /// for content. Recommended best practice is to select a value from a
    /// controlled vocabulary (for example, the DCMI Type Vocabulary
    /// [DCMITYPE]). To describe the physical or digital manifestation of
    /// the resource, use the Format element.
    case type = "dc:type"
}

extension DublinCoreKeys : MetadataKeys {
    public static var localizedGroupTitle: String = loc("Info")
    
    public static var allKeys: [DublinCoreKeys] = [.title, .type, .format, .identifier, .description, .language, .publisher, .contributor, .coverage, .creator, .date, .created, .modified, .relation, .rights, .source, .subject]
    
    public var localizedTitle: String {
        switch self {
        case .format: return loc("Format")
        case .identifier: return loc("Identifier")
        case .modified: return loc("Modified")
        case .contributor: return loc("Contributor")
        case .coverage: return loc("Coverage")
        case .creator: return loc("Creator")
        case .created: return loc("Created")
        case .date: return loc("Date")
        case .description: return loc("Description")
        case .language: return loc("Language")
        case .publisher: return loc("Publisher")
        case .relation: return loc("Relation")
        case .rights: return loc("Rights")
        case .source: return loc("Source")
        case .subject: return loc("Subject")
        case .title: return loc("Title")
        case .type: return loc("Type")
        }
    }
}

/// Keys that are hidden for various reasons
public enum InvisibleKeys : String {
    // Keys from OpenDocumentMetaParser are redundant to those in Office
    case nbPage = "nbPage"
    case nbPara = "nbPara"
    case nbWord = "nbWord"
    case nbCharacter = "nbCharacter"
    case nbTab = "nbTab"
    case nbObject = "nbObject"
    case nbImg = "nbImg"
}

extension InvisibleKeys : MetadataKeys {
    public static var localizedGroupTitle: String = ""
    public static var allKeys: [InvisibleKeys] = [.nbPage, .nbPara, .nbWord, .nbCharacter, .nbTab, .nbObject, nbImg]
    
    public var localizedTitle: String {
        return loc("Hidden")
    }
    
    public var isVisible: Bool {
        return false
    }
}

/// Values correspond to HANDLER_TYPE
public enum TikaContent : String {
    case body = "BODY"
    case ignore = "IGNORE"
    case text = "TEXT"
    case html = "HTML"
    case xml = "XML"
}

public class TikiTorch {
    static let tikaJar = Bundle(for: TikiTorch.self).url(forResource: "tika-app-1.17.jar", withExtension: "")
    static var tikaInSystemCP = false
    
    let ctx: KanjiScriptContext
    let tika: JavaObject
    
    public static func createJVM() throws {
        if JVM.sharedJVM == nil {
            JVM.sharedJVM = try JVM(classpath: TikiTorch.tikaJar.flatMap({ [$0.path] }) ?? [])
            TikiTorch.tikaInSystemCP = true // we've loaded tika in the system jar
        }
    }
    
    public init() throws {
        try TikiTorch.createJVM()
        
        try JVM.sharedJVM.initializeThreadLoader() // needed for concurrent reading
        
        guard let jar = TikiTorch.tikaJar else {
            throw err("Unable to locate tika library")
        }
        
        // only load Tika in a separate classloader if it is not in the system jars
        let jars = TikiTorch.tikaInSystemCP ? [] : [jar]
        
        self.ctx = try KanjiScriptContext(engine: "js", jars: jars)
        self.tika = try ctx.ref(ctx.eval("new org.apache.tika.Tika()"))
        try ctx.bind("tika", value: ctx.ref(.ref(self.tika, ctx)))
        dbg("loaded tiki with version: \(tika)")
    }
    
    public var tikaDescription: String {
        return "\(tika)"
    }
    
    public func detect(url: URL) throws -> String? {
        let detected = try ctx.eval(.val(.str("tika.detect(new java.net.URL('\(url.absoluteString)'))")))
        return try ctx.val(detected).str
    }
    
    public func parseToString(url: URL) throws -> String? {
        let detected = try ctx.eval(.val(.str("tika.parseToString(new java.net.URL('\(url.absoluteString)'))")))
        return try ctx.val(detected).str
    }

    private let extractScript = """
var handlerType = org.apache.tika.sax.BasicContentHandlerFactory.parseHandlerType(tikaHandler || "", org.apache.tika.sax.BasicContentHandlerFactory.HANDLER_TYPE.IGNORE);
var factory = new org.apache.tika.sax.BasicContentHandlerFactory(handlerType, -1);
var autoParser = new org.apache.tika.parser.AutoDetectParser();
var recursiveParser = new org.apache.tika.parser.RecursiveParserWrapper(autoParser, factory);

var context = new org.apache.tika.parser.ParseContext();

context.set(org.apache.tika.parser.PasswordProvider.class,
    new org.apache.tika.parser.PasswordProvider(function(md) { return tikaPassword || ""; })
);

var defaultHandler = new org.xml.sax.helpers.DefaultHandler();

var metadata = new org.apache.tika.metadata.Metadata();
metadata.set(org.apache.tika.metadata.TikaMetadataKeys.RESOURCE_NAME_KEY, tikaURL);
var stream = new java.net.URL(tikaURL).openStream();

try {
  recursiveParser.parse(stream, defaultHandler, metadata, context);
} finally {
  stream.close();
}

var md = recursiveParser.getMetadata();

// serialize the metadata and content to a JSON blob
var writer = new java.io.StringWriter();
org.apache.tika.metadata.serialization.JsonMetadataList.toJson(md, writer);
writer.close();
var str = writer.toString();
"""

    public func extract(url: URL, content: TikaContent, password: String? = nil, transferNative: Bool = true) throws -> [Bric] {
        // bind the string URL to the context
        try ctx.bind("tikaURL", value: ctx.ref(.val(.str(url.absoluteString))))
        try ctx.bind("tikaHandler", value: ctx.ref(.val(.str(content.rawValue))))
        try ctx.bind("tikaPassword", value: ctx.ref(.val(.str(password ?? ""))))
        
        var script = extractScript // TODO: pre-compile script for performance?

        if transferNative {
            script += "JSON.parse(str);"
        } else {
            script += "str;"
        }
        
        // evaluate the given script
        let json = try ctx.eval(.val(.str(script)))

        if transferNative { // direct transfer of native Kanji objects
            return try ctx.val(json).arr ?? []
        } else { // convert via strings
            return try Bric.parse(ctx.val(json).str ?? "").arr ?? []
        }
    }
}
