
## Check out Glimpse and submodules:

```bash
$ git clone -j8 --recurse-submodules --remote-submodules https://github.com/glimpseio/GIO.git
$ cd GIO/
$ git submodule foreach git checkout master
```
 
## Update `master`:

```bash
$ git pull --recurse-submodules --jobs=20
```

## Run all the tests:

```bash
$ xcodebuild -scheme GlimpseAppTests test
```

## Running the app:

  * Open `GIO.xcworkspace` and run the `Glimpse`/`My Mac` target
