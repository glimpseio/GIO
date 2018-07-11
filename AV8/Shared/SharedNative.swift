//
//  GameScene.swift
//  AV8
//
//  Created by Marc Prud'hommeaux on 11/20/16.
//  Copyright © 2016 io.glimpse. All rights reserved.
//

import Avionix

/// This class is shared on all native platforms, but is not part of the shared library.
/// It can be used when code doesn't want to be included as part of the library.
class SharedNative : SharedNativeAPI {
}

protocol SharedNativeAPI {
    var nativePlatformName: String { get }
}

#if os(iOS)
extension SharedNative {
    var nativePlatformName: String { return "iOS" }
}
#endif

#if os(macOS)
extension SharedNative {
    var nativePlatformName: String { return "OSX" }
}
#endif

#if os(tvOS)
extension SharedNative {
    var nativePlatformName: String { return "tvOS" }
}
#endif

#if os(Linux)
extension SharedNative {
    var nativePlatformName: String { return "Liunux" }
}
#endif
