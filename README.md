
## Requirements

Xcode 12.2+ on macOS 11

## Clone repository & submodules

```bash
$ git clone -j8 --recurse-submodules --remote-submodules https://github.com/glimpseio/GIO.git
$ cd GIO/
$ git submodule foreach git checkout master
```
 
## Refresh `master`

```bash
$ git pull --recurse-submodules -j8
```


## Running Glimpse.app

Open `GIO.xcworkspace` in Xcode and run the `Glimpse`/`My Mac` target for the `GUI` workspace.
  
  
## Run tests

All the test can be run from Xcode, or using the following command:

```bash
$ xcodebuild -scheme Glimpse test
```

Note that this will run all the tests in all the dependent modules as well. which usually takes between 1-2 hours. Tests can also be run in the indiviudal modules for speedier and more focused unit testing.

## Repository organization

The Glimpse project is divided into a number of different workspaces, each which contains one more more module and unit tests and is managed in its own separate repository. This modularity provides separation of concerns and help build performance.

A high-level overview of the modules is as follows:

![](modules.png)

### [BricBrac](https://github.com/glimpseio/BricBrac)
Data structures and utilities for `Codable` models. ~15k SLOC.
 * [BricBrac/BricBrac](https://github.com/glimpseio/BricBrac/tree/master/Sources/BricBrac): Provides JSON utilities and structures for `Codable` support, such as a `Bric` enum representing JSON data types and a `OneOf2` *"Either"* type.
 * [BricBrac/Curio](https://github.com/glimpseio/BricBrac/tree/master/Sources/Curio): Swift `struct` code-generator for [JSON Schema](http://json-schema.org) definitions.
 
 ### [Glib](https://github.com/glimpseio/Glib)
 Common shared utilities for parsing, logging, platform interaction, etc. ~22k SLOC.
 * [Glib/Glib](https://github.com/glimpseio/Glib/tree/master/Glib): Utilities that have no dependencies outside of `Foundation`.
 * [Glib/Glob](https://github.com/glimpseio/Glib/tree/master/Glob): Utilities with dependencies (such as `CoreGraphics` and `JavaScriptCore`)
 
 ### [Glean](https://github.com/glimpseio/Glean)
 Spreadsheet & flat-file parsing & database connections for importing, exporting, and processing data. ~5k SLOC.
 * [Glean/GleanModel](https://github.com/glimpseio/Glean/tree/master/Glean): Drivers for connecting to various data sources.
 * [Glean/Glean](https://github.com/glimpseio/Glean/tree/master/GleanModel): Dependency-free data representation `Glean` definitions.

### [Glue](https://github.com/glimpseio/Glue)
General-purpose GUI widgets & utilities. ~21k SLOC.
* [Glue/Glue](https://github.com/glimpseio/Glue/tree/master/Glue): AppKit & UIKit components.
* [Glue/GlueUI](https://github.com/glimpseio/Glue/tree/master/GlueUI): SwiftUI components.

### [Glance](https://github.com/glimpseio/Glance)
Data visualization using the [Vega-Lite](https://vega.github.io) grammer. ~38k SLOC.
 * [Glance/VLModel](https://github.com/glimpseio/Glance/tree/master/VLModel): `Curio`-generated struct representing the [vega-lite](https://vega.github.io/vega-lite/docs/spec.html) visualization specification.
 * [Glance/Glance](https://github.com/glimpseio/Glance/tree/master/Glance): Renders `VLModel` in an embedded browser or headlessly to various output formats: SVG, PNG, PDF, & HTML.
 
 ### [GUI](https://github.com/glimpseio/GUI)
 The Glimpse application. ~27k SLOC.
 * [GUI/GlimpseModel](https://github.com/glimpseio/GUI/tree/master/GlimpseModel): The data model for a `.glimpse` document, which is stored as a compressed JSON representation of a `Glance.VizSpec`
 * [GUI/GlimpseUI](https://github.com/glimpseio/GUI/tree/master/GlimpseUI): SwiftUI components specific to Glimpse.
 * [GUI/Glimpse](https://github.com/glimpseio/GUI/tree/master/Glimpse): The `NSApplication` entry point to Glimpse.app, containing the `NSDocument` implementation of `GlimpseModel` the the `NSWindowController` that manages the application lifecycle and hosts the `GlimpseUI` components.
 * [GUI/GlimpseApp](https://github.com/glimpseio/GUI/tree/master/GlimpseApp): Prototype of iOS version of Glimpse.

## Conceptual Overview

### Basic Architecture

#### ViewModelState & SwiftUI

Glimpse follows a custom variant of the [Model–view–viewmodel (MVVM)](https://en.wikipedia.org/wiki/Model–view–viewmodel) design pattern. Most of the "business logic" of a `.glimpse` document is implement in the `GlimpseModel` framework, which defines a `ViewModel` struct. 

The `ViewModel` is a value type that must reference only to other value types. As such, it provides automatic conformance to `Equatable` and `Hashable`. The `ViewModel`'s model is a `store` property of type `GlimpseSpec`, which contains everything that will be serialized to a `.glimpse` file, which contains the compressed JSON output of `GlimpseSpec`'s `Codable` support). The store is loaded by the Cocoa `NSDocument` system when a `.glimpse` file is loaded by the user.

In addition to the `store` model, `ViewModel` also contains a `state` of type `ViewState`, which contains the current state of the user-interface as pertains to the model. This includes things like the "current selection" and the list of expanded inspectors. The `ViewState` is `Codable`, but it is not stored in the `.glimpse` file with the `GlimpseSpec`: rather, it is automatically serialized and stores in the user's per-document settings by the Cocoa [State Restoration](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621461-encoderestorablestatewithcoder) process. If there are deserialization errors in the state then it is transparently thrown away by the document loading system and a fresh one is used. This has the consequence that properties can be added, removed, and renamed in the `ViewState` without causing errors for the user (unlike the JSON data serialized by the `GlimpseSpec`: those need to be completely backwards-compatible in order to support loading models from previous versions of Glimpse).

The logic in the `GlimpseModel` is all "headless", in that while it defines various properties that *could* be implemented by a graphical user interface (such as a "selection"), the operations that are performed on the model do not require any sort of interface. This makes much of the UI logic testable in `GlimpseModelTests` in a context-free environment.

The graphical user interface of Glimpse is implemented in the `GlimpseUI` framework. One common feature of nearly every `SwiftUI.View` implementation that interacts with the model is that they all contain a `GlimpseContext`, which provides access to the `ViewModelState` via the `vms` property:

```swift
struct LayerTitleEditingView : View {
    @EnvironmentObject var ctx: GlimpseContext
    
    var body: some View {
        TextField("Layer Title", value: $ctx.vms.selectedLayer.title)
    }
}
```

Because the `ViewModelState` is a tree of value types, undo and redo are supported by simply storing the current `ViewModelState` in the undo stack whenever a change is made. This is all handled automatically by the `GlimpseContext` in its `store`'s `willSet` property. An undo event is only triggered by changes to the `store` (since changes to the `state` like changing the current selected outline row or visible inspector tab shouldn't themselves be recorded as an undo-able event), but note that the *entire* `ViewModelState` is saved to the undo stack. This is so that when the action is un-done or re-done, the user interface state in the `ViewState` will be restored to its appearance at the time the `store` change occurred.

In addition to the `ViewState`, some non-restorable and non-undoable state is stored in a `TransientViewState`, which is accessed in `GlimpseContext.tmp`. This structure contains shared user-interface properties that are explicitly *not* meant to be restorable, such as the currently focused items and whether the canvas and data grid are visible. To determine whether a new user interface property should be added to `ViewState` or `TransientViewState`, consider whether it makes sense to that user-interface feature should be part of the undo/redo process or not. Properties can be moved between the two structures between versions, so it generally makes sense to first add new properties to `TransientViewState` and then, if it makes sense, move them into `ViewState` later.






