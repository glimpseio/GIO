
## Check out Glimpse and submodules:

```bash
$ git clone --jobs=20 --recurse-submodules --remote-submodules https://github.com/glimpseio/GIO.git
```
 
## Update `master`:

```bash
$ git pull --recurse-submodules --jobs=20
```

## Run all the tests:

```bash
$ xcodebuild -workspace GIO/GIO.xcworkspace -scheme GlimpseAppTests test
```

## Running the app:

  * Open `GIO.xcworkspace` and run the `Glimpse`/`My Mac` target
