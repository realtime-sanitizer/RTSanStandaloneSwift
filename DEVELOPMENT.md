# Swift RealtimeSanitizer dev notes

## Tests

When running tests, test runner needs to link sanitizer library. Since this executable is out of our control, we need to use `DYLD_INSERT_LIBRARIES` to force test runner to load sanitizer library.
The issue is foundamentaly very similar to DAW -> Plugin interaction explained [here](https://forum.juce.com/t/using-realtimesanitizer-inside-daws/64557).

This environment variable is already set up in scheme settings in Xcode, but you might need to change to path on your machine for tests to work.

E.g. when you run the test, you will get the following error:

```
==64625==ERROR: Interceptors are not working. This may be because RealtimeSanitizer is loaded too late (e.g. via dlopen). Please launch the executable with:
DYLD_INSERT_LIBRARIES=/Users/josipcavar/Library/Developer/Xcode/DerivedData/SwiftRealtimeSanitizer-dgcolftpwmfxydcenfpxifrysmjc/Build/Products/Debug/libclang_rt.rtsan_osx_dynamic.dylib
"interceptors not installed" && 0
```

Open Scheme settings and change `DYLD_INSERT_LIBRARIES` to environment variable to path in the log.

Additionally, for tests to work, we need the following `RTSAN_OPTIONS`:
- `abort_on_error=false`
- `halt_on_error=false`

These are both enabled in `SwiftRealtimeSanitizer-Package` scheme.

Tests currently work by intercepting stderr output and making decisions based on that. This is not ideal, but seems like the only way to avoid test crash:

- `abort_on_error` has to be false, otherwise the test will fail as the process will abort
- `halt_on_error` has to be false, otherwise the test will fail as it will finish with a non-zero exit code
- if the two above are false, death callback is not invoked
- if `halt_on_error` is true, death callback is invoked but test will fail (due to non-zero) exit code

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
- [ ] Documentation
- [ ] Use Clang implementation when available in Swift C++ interop
- [ ] Discuss possible native Swift integration
- [ ] Death callback doesn't seem to be useful for testing since after it is called, process exists.
- [ ] Use SPM traits once they are availble in Swift 6.1
