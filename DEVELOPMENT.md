# Swift RealtimeSanitizer dev notes

## Tests

Runtime tests use Swift 6.2 exit tests (`#expect(processExitsWith:)`). Each violation test runs in an isolated child process where RTSan can abort normally — tests expecting a violation use `.failure` and tests expecting no violation use `.success`.

### macOS

On macOS, the test runner needs to link the sanitizer library. Since this executable is out of our control, we use `DYLD_INSERT_LIBRARIES` to force the test runner to load the sanitizer library. The issue is fundamentally very similar to DAW -> Plugin interaction explained [here](https://forum.juce.com/t/using-realtimesanitizer-inside-daws/64557).

This environment variable is already set up in scheme settings in Xcode, but you might need to change the path on your machine for tests to work.

E.g. when you run the test, you will get the following error:

```
==64625==ERROR: Interceptors are not working. This may be because RealtimeSanitizer is loaded too late (e.g. via dlopen). Please launch the executable with:
DYLD_INSERT_LIBRARIES=/Users/josipcavar/Library/Developer/Xcode/DerivedData/RTSanStandaloneSwift-dgcolftpwmfxydcenfpxifrysmjc/Build/Products/Debug/libclang_rt.rtsan_osx_dynamic.dylib
"interceptors not installed" && 0
```

Open Scheme settings and change `DYLD_INSERT_LIBRARIES` environment variable to the path in the log.

### Linux

On Linux, no special environment variables are needed — just run `swift test -v`.

## Build process

Clone LLVM project and build rtsan following procedure from [the docs](https://clang.llvm.org/docs/RealtimeSanitizer.html).

### macOS and iOS

macOS and iOS versions use `xcframework` format to ship a prebuilt rtsan dynamic libraries for each platform.
This avoids the need to compile LLVM sanitizer when integrating this library.

One differences compared to default build process from the docs is that in order to satisfy `xcodebuild`, you will also need to pass `DCOMPILER_RT_ENABLE_MACCATALYST=OFF` flag. Without this flag, the following step doesn't work as xcodebuild refuses to bundle such a dylib. This needs to be investigated further.

Once you build rtsan, you can generate `xcframework` in the following way:

```
xcrun xcodebuild -create-xcframework \
  -library lib/clang/20/lib/darwin/libclang_rt.rtsan_ios_dynamic.dylib -headers RTSanStandaloneSwift/rtsan/include/rtsan_standalone \
  -library lib/clang/20/lib/darwin/libclang_rt.rtsan_iossim_dynamic.dylib -headers RTSanStandaloneSwift/rtsan/include/rtsan_standalone \
  -library lib/clang/20/lib/darwin/libclang_rt.rtsan_osx_dynamic.dylib -headers RTSanStandaloneSwift/rtsan/include/rtsan_standalone \
  -output rtsan.xcframework
```

### Linux

Run Swift docker image using instructions [here](https://www.swift.org/install/linux/docker/).

Using `apt install` install:
- `cmake`
- `python3`
- `ccache`
- `clang`
- `ninja-build`

In order to compile LLVM successfully, you need to update default compilers to clang:

```
export CC=clang
export CXX=clang++
```
