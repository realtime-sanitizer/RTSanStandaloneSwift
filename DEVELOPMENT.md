# SwiftRealtimeSanitizer dev notes

## Development Setup

Currently, this project contains two schemes:
- SwiftRealtimeSanitizer-Package - Used to develop and run tests
- Playground - A simple executable used to play with the code

## Tests

For some reason, when running tests rtsan gets linked too late and therefore doesn't work.
Temporary solution to this is to use `DYLD_INSERT_LIBRARIES` in Xcode scheme settings.

When you run the test, you will get the following error:

```
==64625==ERROR: Interceptors are not working. This may be because RealtimeSanitizer is loaded too late (e.g. via dlopen). Please launch the executable with:
DYLD_INSERT_LIBRARIES=/Users/josipcavar/Library/Developer/Xcode/DerivedData/SwiftRealtimeSanitizer-dgcolftpwmfxydcenfpxifrysmjc/Build/Products/Debug/libclang_rt.rtsan_osx_dynamic.dylib
"interceptors not installed" && 0
```

Open Scheme settings and add `DYLD_INSERT_LIBRARIES` to environment variables.

Additionally, for tests to work, we need the following `RTSAN_OPTIONS`:
- abort_on_error=false
- halt_on_error=false

These are both enabled in `SwiftRealtimeSanitizer-Package` scheme.



## Build process

Clone LLVM project and build rtsan following procedure from [the docs](https://clang.llvm.org/docs/RealtimeSanitizer.html).

### macOS and iOS

macOS and iOS versions use `xcframework` format to ship a prebuilt rtsan dynamic libraries for each platform.
This avoids the need to compile LLVM sanitizer when integrating this library.

There are two differences compared to default build process from the docs:

- In order to satisfy `xcodebuild`, you will also need to pass `DCOMPILER_RT_ENABLE_MACCATALYST=OFF` flag. Without this flag, the following step doesn't work as xcodebuild refuses to bundle such a dylib. This needs to be investigated further.
- In `compiler-rt/cmake/Modules/AllSupportedArchDefs.cmake`, enable arm64e:

```
if(APPLE)
  set(ARM64 arm64 arm64e)
  ...
```


Once you build rtsan, you can generate `xcframework` in the following way:

```
xcrun xcodebuild -create-xcframework \
  -library lib/clang/20/lib/darwin/libclang_rt.rtsan_ios_dynamic.dylib -headers SwiftRealtimeSanitizer/Sources/RealtimeSanitizerCBindings/include \
  -library lib/clang/20/lib/darwin/libclang_rt.rtsan_iossim_dynamic.dylib -headers SwiftRealtimeSanitizer/Sources/RealtimeSanitizerCBindings/include \
  -library lib/clang/20/lib/darwin/libclang_rt.rtsan_osx_dynamic.dylib -headers SwiftRealtimeSanitizer/Sources/RealtimeSanitizerCBindings/iinclude \
  -output rtsan.xcframework
```


### Linux

Note: I am not a Linux user so my setup is likely not optimal.

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

## TODO:

- [ ] Call Ensure initialized at appropriate point
- [ ] Tests only work with dyld_insert_libraries
- [ ] Documentation
- [ ] Use Clang implementation when available in Swift C++ interop
- [ ] Discuss possible native Swift integration
- [ ] Death callback doesn't seem to be useful for testing since after it is called, process exists.
