/// A function annotated with `NonBlocking` macro
/// will raise an error if realtime violation is detected.
/// For example:
///
///     @NonBlocking
///     func process() { print("") }
///
/// will error at runtime with:
///
///     ERROR: RealtimeSanitizer: unsafe-library-call
///     Intercepted call to real-time unsafe function `malloc` in real-time context!
@attached(body)
public macro NonBlocking(in configuration: StaticString = "DEBUG") = #externalMacro(module: "RealtimeSanitizerMacros", type: "NonBlocking")

/// Allows the user to specify a function as not-real-time-safe.
///
/// For example:
///
///     @Blocking
///     func myBlockingFunction() {
///         // unbounded loop
///     }
@attached(body)
public macro Blocking(in configuration: StaticString = "DEBUG") = #externalMacro(module: "RealtimeSanitizerMacros", type: "Blocking")

@_exported import RealtimeSanitizerCore
