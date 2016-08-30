
* Build issue: test cases will build but won't launch on iOS

  You may get the error:

  ```Reason: image not found, NSBundlePath=Products/Debug-iphonesimulator/GlimpseCoreTests.xctest, NSLocalizedDescription=The bundle “GlimpseCoreTests” couldn’t be loaded because it is damaged or missing necessary resources.}```

  Looking at the log, you might see something like:

  ```(dlopen_preflight(/Users/mprudhom/Library/Developer/Xcode/DerivedData/Glimpse-bkrljxkwucpghzhjtlkwtuxwwspq/Build/Products/Debug-iphonesimulator/GlimpseCoreTests.xctest/GlimpseCoreTests): Library not loaded: @rpath/libswiftCore.dylib```

  The problem seems to be that the test target Framework on Mac defaults to having the Linking "Runtime Search Paths" defaults to 

  LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/../Frameworks @loader_path/../Frameworks

  But on iOS it is:

  LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/Frameworks @loader_path/Frameworks

  The trick is to aggregate it all together:

  LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/../Frameworks @executable_path/Frameworks @loader_path/../Frameworks @loader_path/Frameworks

