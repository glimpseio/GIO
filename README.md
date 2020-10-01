
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


## Running Glimpse.app:

Open `GIO.xcworkspace` in Xcode and run the `Glimpse`/`My Mac` target for the `GUI` workspace.
  
  
## Run tests

All the test can be run from Xcode, or using the following command:

```bash
$ xcodebuild -scheme Glimpse test
```

Note that this will run all the tests in all the dependent modules as well. which usually takes between 1-2 hours. Tests can also be run in the indiviudal modules for speedier and more focused unit testing.

## Modules & Workspaces

The Glimpse project is broken into a number of different workspaces, each which contains one more more module and unit tests. This modularity provides separations of concerns and help build performance.

A high-level overview of the modules is as follows:

### [BricBrac](https://github.com/glimpseio/BricBrac): Data structures and utilities for `Codable` models
 * [BricBrac/BricBrac](https://github.com/glimpseio/BricBrac/tree/master/Sources/BricBrac): Provides `OneOf2` *"Either"* type and other affordances
 * [BricBrac/Curio](https://github.com/glimpseio/BricBrac/tree/master/Sources/Curio): Generates `Codable` structs from [JSON Schema](http://json-schema.org) definitions
 
 ### [Glib](https://github.com/glimpseio/Glib)
 * [Glib/Glib](https://github.com/glimpseio/Glib/tree/master/Glib)
 * [Glib/Glob](https://github.com/glimpseio/Glib/tree/master/Glob)
 
 ### [Glean](https://github.com/glimpseio/Glean)
 * [Glean/GleanModel](https://github.com/glimpseio/Glean/tree/master/Glean)
 * [Glean/Glean](https://github.com/glimpseio/Glean/tree/master/GleanModel)

### [Glance](https://github.com/glimpseio/Glance)
 * [Glance/Glance](https://github.com/glimpseio/Glance/tree/master/Glance)
 * [Glance/VLModel](https://github.com/glimpseio/Glance/tree/master/VLModel)
 
 ### [Glue](https://github.com/glimpseio/Glue)
 * [Glue/Glue](https://github.com/glimpseio/Glue/tree/master/Glue)
 * [Glue/GlueUI](https://github.com/glimpseio/Glue/tree/master/GlueUI)
 
 ### [GUI](https://github.com/glimpseio/GUI)
 * [GUI/GlimpseModel](https://github.com/glimpseio/GUI/tree/master/GlimpseModel)
 * [GUI/GlimpseUI](https://github.com/glimpseio/GUI/tree/master/GlimpseUI)
 * [GUI/Glimpse](https://github.com/glimpseio/GUI/tree/master/Glimpse)
 * [GUI/GlimpseApp](https://github.com/glimpseio/GUI/tree/master/GlimpseApp)

