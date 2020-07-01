
## Check out Glimpse and submodules:

```bash
$ git clone --recurse-submodules --remote-submodules https://github.com/glimpseio/GIO.git
$ git submodule foreach git checkout master
```
 
## Run all the tests:

```bash
$ xcodebuild -workspace GIO/GIO.xcworkspace -scheme GlimpseAppTests test
```

## Running the app:

  * Open `GIO.xcworkspace` and run the `Glimpse`/`My Mac` target
