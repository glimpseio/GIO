
## Check out Glimpse and submodules:

```bash
$ git clone --jobs=20 --recurse-submodules --remote-submodules https://github.com/glimpseio/GIO.git
```
 
## Update `master`:

$ git pull --recurse-submodules --jobs=20

```bash
## Run all the tests:
```

```bash
$ xcodebuild -workspace GIO/GIO.xcworkspace -scheme GlimpseAppTests test
```

## Running the app:

  * Open `GIO.xcworkspace` and run the `Glimpse`/`My Mac` target

  SF Symbols Fallback


  2020-07-27 12:45:57.847573-0400 Glimpse[73410:2811370] CoreText note: Client requested name ".SF Symbols Fallback", it will get Times-Roman rather than the intended font. All system UI font access should be through proper APIs such as CTFontCreateUIFontForLanguage() or +[NSFont systemFontOfSize:].


