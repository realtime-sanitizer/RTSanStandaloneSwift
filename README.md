# RTSanStandaloneSwift

This is a wrapper for the standalone version of RealtimeSanitizer (RTSan) to detect real-time violations in Swift applications.
You can find more information in the [Official Clang Docs](https://clang.llvm.org/docs/RealtimeSanitizer.html) and the [RTSan Repository](https://github.com/realtime-sanitizer/rtsan).

## Usage

Mark a real-time function with the `@NonBlocking` macro:

```swift
import RealtimeSanitizer

@NonBlocking
func process() { print("") }
```

At runtime, real-time violations are presented with a stack trace:

```bash
ERROR: RealtimeSanitizer: unsafe-library-call
Intercepted call to real-time unsafe function `malloc` in real-time context!
    #0 0x000102b86fa0 in malloc rtsan_interceptors_posix.cpp:720
    #1 0x0001801c9db0 in _malloc_type_malloc_outlined+0x70 (libsystem_malloc.dylib:arm64+0xfdb0)
    #2 0x000194adfa68 in swift_slowAlloc+0x24 (libswiftCore.dylib:arm64+0x2f8a68)
    #3 0x000194adfd50 in swift_allocObject+0x30 (libswiftCore.dylib:arm64+0x2f8d50)
    #4 0x00019480a5d0 in _allocateUninitializedArray<A>(_:)+0x50 (libswiftCore.dylib:arm64+0x235d0)
    #5 0x00010264e75c in process() @__swiftmacro_10Playground7process11NonBlockingfMb_.swift:3
    #6 0x00010264e724 in main main.swift:8
    #7 0x00010296540c  (<unknown module>)
    #8 0x0001026a6270 in start+0xb14 (dyld:arm64+0x6270)

SUMMARY: RealtimeSanitizer: unsafe-library-call (libsystem_malloc.dylib:arm64+0xfdb0) in _malloc_type_malloc_outlined+0x70
```

## Setup

To use RTSanStandaloneSwift, add it as a SPM package dependency to your `Package.swift` file, or in Xcode UI:

Package dependency:
```
.package(url: "https://github.com/realtime-sanitizer/RTSanStandaloneSwift", .upToNextMajor(from: "0.1.0"))
```

Target dependency:
```
.productItem(name: "RealtimeSanitizer", package: "RTSanStandaloneSwift")
```

By default, `@NonBlocking` macro will only report violations in `DEBUG` configuration. You can configure this behaviour by providing your custom configuration:

```swift
@NonBlocking(in: "STAGING")
func process() { print("") }
```

Make sure to call `RealtimeSanitizer.ensureInitialized()` early in your process lifecycle.

### Excluding RTSanStandaloneSwift from production builds

While RTSanStandaloneSwift will not have runtime overhead if configuration does not match, it is still recommended to remove linked libraries from production builds.

You can do this by explicitly excluding RTSanStandaloneSwift in specific configurations:

```bash
EXCLUDED_SOURCE_FILE_NAMES = RealtimeSanitizer.o RealtimeSanitizerCore.o
```

## RTSan Options

You can set different options in RTSan by providing `RTSAN_OPTIONS` environment variable:

```sh
RTSAN_OPTIONS=halt_on_error=false
```

For a full list of options see here: https://clang.llvm.org/docs/RealtimeSanitizer.html#run-time-flags.

## Sandboxed apps

For sandboxed apps, it is recommended to update your scheme with the following environment options:

```
RTSAN_OPTIONS=symbolize=true:external_symbolizer_path=""
```

This will force in-process sybolizer and avoid permission issues during symbolication.

## Availability

RTSanStandaloneSwift is available on macOS, iOS, iOS Simulator and Linux.

> [!WARNING]
> Linux support is very basic and we welcome contributions.

## Contact

RTSan was invented by David Trevelyan and Ali Barker. The C++ upstream implementation was authored by David Trevelyan and Chris Apple, while the Swift
wrapper was developed by Josip Cavar. Feedback and contributions are welcome!

- **Discord**: [RealtimeSanitizer (RTSan)](https://discord.com/invite/DZqjbmSZzZ) Discord Channel
- **Email**: [realtime.sanitizer@gmail.com](mailto:realtime.sanitizer@gmail.com)
- **GitHub Issues**: Submit your queries or suggestions directly to this repository.
