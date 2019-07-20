//
//  Vektorz.h
//  Vektorz
//
//  Created by Marc Prud'hommeaux on 7/16/19.
//  Copyright © 2019 Glimpse I/O. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for Vektorz.
FOUNDATION_EXPORT double VektorzVersionNumber;

//! Project version string for Vektorz.
FOUNDATION_EXPORT const unsigned char VektorzVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Vektorz/PublicHeader.h>


#import <CoreGraphics/CoreGraphics.h>


typedef NSInteger SVGReaderOptions;
typedef NSInteger SVGWriterOptions;


// MARK: CGSVGAtomRef
typedef void* CGSVGAtom;

CGSVGAtom CGSVGAtomFromString(CFStringRef);
CFStringRef CGSVGAtomCopyString(CGSVGAtom);
CGSVGAtom CGSVGAtomFromCString(char**);
void* CGSVGAtomGetCString(void *ptr);


// MARK: CGSVGPathCommandRef
typedef CFTypeRef CGSVGPathCommandRef;

CFTypeID CGSVGPathCommandGetTypeID(CGSVGPathCommandRef);
void* CGSVGPathCommandAppendFloats(CGSVGPathCommandRef);
void* CGSVGPathCommandAppendPoint(CGSVGPathCommandRef);
void* CGSVGPathCommandGetFloatAtIndex(CGSVGPathCommandRef);
void* CGSVGPathCommandGetFloatCount(CGSVGPathCommandRef);
void* CGSVGPathCommandGetType(CGSVGPathCommandRef);



// MARK: CGSVGPathRef
typedef CFTypeRef CGSVGPathRef;

CFTypeID CGSVGPathGetTypeID(CGSVGPathRef);
void* CGSVGPathAppendCommand(CGSVGPathRef, CGSVGPathCommandRef);
CGSVGPathRef CGSVGPathCreate();
CGSVGPathRef CGSVGPathCreateWithCGPath(CGPathRef path);
void* CGSVGPathCreateCGPath(void *ptr);
CGSVGPathCommandRef CGSVGPathGetCommandAtIndex(void *ptr);
NSInteger CGSVGPathGetCommandCount(void *ptr);
//void* CGSVGPathRetain(CGSVGPathRef);
//void* CGSVGPathRelease(CGSVGPathRef);




// MARK: CGSVGAttributeRef
typedef CFTypeRef CGSVGAttributeRef;
CFTypeID CGSVGAttributeTypeID = 999; // FIXME

CFTypeID CGSVGAttributeGetTypeID(CGSVGAttributeRef);

CFStringRef CGSVGAttributeGetName(CGSVGAttributeRef);
NSInteger CGSVGAttributeGetType(CGSVGAttributeRef);

CGSVGAttributeRef CGSVGAttributeCreateWithAtom(void *ptr);
void* CGSVGAttributeGetAtom(CGSVGAttributeRef);

CGSVGAttributeRef CGSVGAttributeCreateWithColor(void *ptr);

CGSVGAttributeRef CGSVGAttributeCreateWithFloat(CGFloat, CFStringRef);
CGFloat CGSVGAttributeGetFloat(CGSVGAttributeRef);

CGSVGAttributeRef CGSVGAttributeCreateWithFloats(void *ptr);
void* CGSVGAttributeGetFloatCount(CGSVGAttributeRef);

void* CGSVGAttributeGetFloats(CGSVGAttributeRef);
CGSVGAttributeRef CGSVGAttributeCreateWithGradient(void *ptr);

CGSVGAttributeRef CGSVGAttributeCreateWithPaint(void *ptr);
void* CGSVGAttributeGetPaint(CGSVGAttributeRef);

CGSVGAttributeRef CGSVGAttributeCreateWithPath(void *ptr);
void* CGSVGAttributeGetPath(CGSVGAttributeRef);

CGSVGAttributeRef CGSVGAttributeCreateWithPoint(void *ptr);
void* CGSVGAttributeGetPoint(CGSVGAttributeRef);

CGSVGAttributeRef CGSVGAttributeCreateWithRect(void *ptr);
void* CGSVGAttributeGetRect(CGSVGAttributeRef);

CGSVGAttributeRef CGSVGAttributeCreateWithCString(void *ptr);
CGSVGAttributeRef CGSVGAttributeCreateWithString(void *ptr);
void* CGSVGAttributeCopyString(void *ptr);

CGSVGAttributeRef CGSVGAttributeCreateWithTransform(void *ptr);
void* CGSVGAttributeGetTransform(CGSVGAttributeRef);

//void* CGSVGAttributeRetain(CGSVGAttributeRef);
//void* CGSVGAttributeRelease(CGSVGAttributeRef);



// MARK: CGSVGAttributeMapRef
typedef CFTypeRef CGSVGAttributeMapRef;
CFTypeID CGSVGAttributeMapTypeID = 272;

CFTypeID CGSVGAttributeMapGetTypeID(CGSVGAttributeMapRef);
NSInteger CGSVGAttributeMapGetCount(CGSVGAttributeMapRef);

CGSVGAttributeMapRef CGSVGAttributeMapCreate();
CGSVGAttributeMapRef CGSVGAttributeMapCreateWithDefaults(void *ptr);

void* CGSVGAttributeMapEnumerate(CGSVGAttributeMapRef);

CGSVGAttributeRef CGSVGAttributeMapGetAttribute(CGSVGAttributeMapRef, CFStringRef);
void CGSVGAttributeMapSetAttribute(CGSVGAttributeMapRef, CGSVGAttributeRef, CFStringRef);

//void* CGSVGAttributeMapRetain(CGSVGAttributeMapRef);
//void* CGSVGAttributeMapRelease(CGSVGAttributeMapRef);



// MARK: CGSVGNodeRef
typedef CFTypeRef CGSVGNodeRef;
CFTypeID CGSVGNodeTypeID = 271;

CFTypeID CGSVGNodeGetTypeID(CGSVGNodeRef); // 271
void* CGSVGNodeAddChild(CGSVGNodeRef);
NSInteger CGSVGNodeGetType(CGSVGNodeRef);
void* CGSVGNodeCopy(CGSVGNodeRef);
CFStringRef CGSVGNodeCopyName(CGSVGNodeRef);
CFStringRef CGSVGNodeCopyStringIdentifier(CGSVGNodeRef);
CFStringRef CGSVGNodeCopyText(CGSVGNodeRef);
CGSVGNodeRef CGSVGNodeCreate(CFStringRef);
CGSVGNodeRef CGSVGNodeCreateGroupNode();

void* CGSVGNodeEnumerate(void *ptr);
void* CGSVGNodeFindAttribute(void *ptr);
void* CGSVGNodeFindChildWithCStringIdentifier(void *ptr);
void* CGSVGNodeFindChildWithStringIdentifier(void *ptr);

CGSVGAttributeMapRef CGSVGNodeGetAttributeMap(CGSVGNodeRef);
CGRect CGSVGNodeGetBoundingBox(CGSVGNodeRef);
CGSVGNodeRef CGSVGNodeGetChildAtIndex(CGSVGNodeRef, NSInteger);

NSInteger CGSVGNodeGetChildCount(CGSVGNodeRef);
CGSVGNodeRef CGSVGNodeGetParent(CGSVGNodeRef);

void* CGSVGNodeGetRelativeBoundingBox(CGSVGNodeRef); // does not seem to be a CGRect
void* CGSVGNodeRemoveChildAtIndex(CGSVGNodeRef, NSInteger);
void* CGSVGNodeSetAttribute(void *ptr);
void* CGSVGNodeSetAttributeMap(CGSVGNodeRef, CGSVGAttributeMapRef);
void* CGSVGNodeSetCStringComment(CGSVGNodeRef);
void* CGSVGNodeSetCStringIdentifier(CGSVGNodeRef);
void* CGSVGNodeSetCStringText(CGSVGNodeRef);
void* CGSVGNodeSetStringComment(CGSVGNodeRef);
void* CGSVGNodeSetStringIdentifier(CGSVGNodeRef);
void* CGSVGNodeSetStringText(CGSVGNodeRef);
//void* CGSVGNodeRetain(CGSVGNodeRef);
//void* CGSVGNodeRelease(CGSVGNodeRef);


CGSVGNodeRef CGSVGRootNodeCreate();
NSInteger CGSVGRootNodeGetAspectRatio(CGSVGNodeRef);
void CGSVGRootNodeSetAspectRatio(CGSVGNodeRef, NSInteger);
void* CGSVGRootNodeGetAspectRatioMeetOrSlice(CGSVGNodeRef);
void CGSVGRootNodeSetAspectRatioMeetOrSlice(CGSVGNodeRef);
CGSize CGSVGRootNodeGetSize(CGSVGNodeRef);
void CGSVGRootNodeSetSize(CGSVGNodeRef, CGSize);
CGRect CGSVGRootNodeGetViewbox(CGSVGNodeRef);
void CGSVGRootNodeSetViewbox(CGSVGNodeRef, CGRect);


CGSVGNodeRef CGSVGShapeNodeCreate();
void* CGSVGShapeNodeCopyText(CGSVGNodeRef);
void* CGSVGShapeNodeGetPrimitive(CGSVGNodeRef);
void* CGSVGShapeNodeGetCircleGeometry(CGSVGNodeRef);
void* CGSVGShapeNodeSetCircleGeometry(CGSVGNodeRef);
void* CGSVGShapeNodeGetEllipseGeometry(CGSVGNodeRef);
void* CGSVGShapeNodeSetEllipseGeometry(CGSVGNodeRef);
void* CGSVGShapeNodeGetFloatCount(CGSVGNodeRef);
void* CGSVGShapeNodeGetFloats(CGSVGNodeRef);
void* CGSVGShapeNodeSetFloats(CGSVGNodeRef);
void* CGSVGShapeNodeGetLineGeometry(CGSVGNodeRef);
void* CGSVGShapeNodeSetLineGeometry(CGSVGNodeRef);
void* CGSVGShapeNodeGetPath(CGSVGNodeRef);
void* CGSVGShapeNodeSetPath(CGSVGNodeRef);
void* CGSVGShapeNodeGetRectGeometry(CGSVGNodeRef);
void* CGSVGShapeNodeSetRectGeometry(CGSVGNodeRef);


// MARK: CGSVGCanvasRef
typedef CFTypeRef CGSVGCanvasRef;
CFTypeID CGSVGCanvasTypeID = 275;

CFTypeID CGSVGCanvasGetTypeID(CGSVGCanvasRef); // 275
CGSVGNodeRef CGSVGCanvasGetCurrentGroup(CGSVGCanvasRef);
CGSVGNodeRef CGSVGCanvasAddEllipseInRect(CGSVGCanvasRef, CGRect); // __ZN9SVGCanvas16addEllipseInRectE6CGRect
CGSVGNodeRef CGSVGCanvasAddLine(CGSVGCanvasRef, CGPoint, CGPoint); // __ZN9SVGCanvas7addLineE7CGPointS0_
CGSVGNodeRef CGSVGCanvasAddPath(CGSVGCanvasRef, CGSVGPathRef); // __ZN9SVGCanvas7addPathEv
CGSVGNodeRef CGSVGCanvasAddPolygon(CGSVGCanvasRef, CGFloat[], NSInteger); // __ZN9SVGCanvas10addPolygonERKNSt3__16vectorI7CGPointNS0_9allocatorIS2_EEEE
CGSVGNodeRef CGSVGCanvasAddPolyline(CGSVGCanvasRef, CGFloat[], NSInteger); // __ZN9SVGCanvas11addPolylineERKNSt3__16vectorI7CGPointNS0_9allocatorIS2_EEEE
CGSVGNodeRef CGSVGCanvasAddRect(CGSVGCanvasRef, CGRect); // __ZN9SVGCanvas7addRectE6CGRect
CGSVGNodeRef CGSVGCanvasPopGroup(CGSVGCanvasRef); // __ZN9SVGCanvas8popGroupEv
CGSVGNodeRef CGSVGCanvasPushGroup(CGSVGCanvasRef); // __ZN9SVGCanvas9pushGroupEv
//void* CGSVGCanvasRetain(CGSVGCanvasRef);
//void* CGSVGCanvasRelease(CGSVGCanvasRef);


// MARK: CGSVGColorRef
typedef CFTypeRef CGSVGColorRef;

CGSVGColorRef CGSVGColorCreateCGColor(CGColorRef);
CGSVGColorRef CGSVGColorCreateFromCString(void *ptr);
CGSVGColorRef CGSVGColorCreateFromString(CFStringRef);
CGSVGColorRef CGSVGColorCreateRGBA(void *ptr);


// MARK: CGSVGDocumentRef
typedef CFTypeRef CGSVGDocumentRef;
CFTypeID CGSVGDocumentTypeID = 270;

CFTypeID CGSVGDocumentGetTypeID(CGSVGDocumentRef); // 270
void* CGSVGDocumentContainsWideGamutContent(CGSVGDocumentRef);
CGSVGDocumentRef CGSVGDocumentCreate(CGSize size);
CGSVGDocumentRef CGSVGDocumentCreateFromData(CFDataRef, SVGReaderOptions);
CGSVGDocumentRef CGSVGDocumentCreateFromDataProvider(CGDataProviderRef);
CGSVGDocumentRef CGSVGDocumentCreateFromURL(CFURLRef, CFDictionaryRef);

void* CGSVGDocumentAddNamedStyle(CGSVGDocumentRef);
void* CGSVGDocumentGetNamedStyle(CGSVGDocumentRef);

void* CGSVGDocumentCreateOptionVariablesKey(void *ptr);
CGSVGCanvasRef CGSVGDocumentGetCanvas(CGSVGDocumentRef);
CGSize CGSVGDocumentGetCanvasSize(CGSVGDocumentRef);
CGSVGNodeRef CGSVGDocumentGetRootNode(CGSVGDocumentRef);
void* CGSVGDocumentOptionStrictKey(CGSVGDocumentRef);
void CGSVGDocumentWriteToData(CGSVGDocumentRef, CFMutableDataRef, SVGWriterOptions); // _ZN11SVGDocument5writeEP8__CFDataP16SVGWriterOptions
void CGSVGDocumentWriteToURL(CGSVGDocumentRef); // __ZN11SVGDocument5writeEPK7__CFURLP16SVGWriterOptions
//void CGSVGDocumentRetain(CGSVGDocumentRef);
//void CGSVGDocumentRelease(CGSVGDocumentRef);


// MARK: CGSVGGradientRef
typedef CFTypeRef CGSVGGradientRef;

CFTypeID CGSVGGradientGetTypeID(CGSVGGradientRef);
void* CGSVGGradientAddStop(void *ptr);
CGSVGGradientRef CGSVGGradientCreate(void *ptr);
void* CGSVGGradientGetEnd(void *ptr);
void* CGSVGGradientGetNumberOfStops(void *ptr);
void* CGSVGGradientGetSpread(void *ptr);
void* CGSVGGradientGetStart(void *ptr);
void* CGSVGGradientGetStop(void *ptr);
void* CGSVGGradientGetType(void *ptr);
void* CGSVGGradientSetEnd(void *ptr);
void* CGSVGGradientSetSpread(void *ptr);
void* CGSVGGradientSetStart(void *ptr);
//void* CGSVGGradientRelease(CGSVGGradientRef);
//void* CGSVGGradientRetain(CGSVGGradientRef);


// MARK: CGSVGGradientStopRef
typedef CFTypeRef CGSVGGradientStopRef;

CFTypeID CGSVGGradientStopGetTypeID(CGSVGGradientStopRef);
CGSVGGradientStopRef CGSVGGradientStopCreateWithColor(void *ptr);
void* CGSVGGradientStopGetColor(CGSVGGradientStopRef);
void* CGSVGGradientStopGetOffset(CGSVGGradientStopRef);
//void* CGSVGGradientStopRelease(CGSVGGradientStopRef);
//void* CGSVGGradientStopRetain(CGSVGGradientStopRef);


// MARK: CGSVGPaintRef
typedef CFTypeRef CGSVGPaintRef;

CFTypeID CGSVGPaintGetTypeID(CGSVGPaintRef);
CGSVGPaintRef CGSVGPaintCreateNone(void *ptr);
CGSVGPaintRef CGSVGPaintCreateWithColor(void *ptr);
CGSVGPaintRef CGSVGPaintCreateWithGradient(void *ptr);
CGSVGPaintGetOpacity(CGSVGPaintRef, CGFloat);
CGFloat CGSVGPaintSetOpacity(CGSVGPaintRef);
void* CGSVGPaintGetColor(CGSVGPaintRef);
void* CGSVGPaintGetGradient(CGSVGPaintRef);
void* CGSVGPaintGetType(CGSVGPaintRef);
void* CGSVGPaintIsVisible(CGSVGPaintRef);
//void* CGSVGPaintRetain(CGSVGPaintRef);
//void* CGSVGPaintRelease(CGSVGPaintRef);



void CGContextDrawSVGDocument(CGContextRef, CGSVGDocumentRef);
void CGContextDrawSVGNode(CGContextRef, CGSVGNodeRef); // ____ZL11DrawSVGNodeP21CGSVGDrawStateContextP9CGSVGNode_block_invoke
