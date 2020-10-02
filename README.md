
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

#### Rendering & Exporting

#### ViewModelState & SwiftUI

 * Store
 * State
 * Transient

##### A Note on Performance

### Design Philosophy

## Documentation


