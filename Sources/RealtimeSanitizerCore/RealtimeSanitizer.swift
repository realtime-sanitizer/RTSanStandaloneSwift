private import rtsan

public enum RealtimeSanitizer {
    /// Initializes rtsan if it has not been initialized yet.
    /// Used by the RTSan runtime to ensure that rtsan is initialized before any
    /// other rtsan functions are called.
    public static func ensureInitialized() {
        __rtsan_ensure_initialized()
    }

    /// Re-enable all RTSan error reporting.
    /// Must follow a call to `RealtimeSanitizer.disable()`.
    public static func enable() {
        __rtsan_enable()
    }

    /// Disable all RTSan error reporting in an otherwise real-time context.
    /// Must be paired with a call to `RealtimeSanitizer.enable()`
    public static func disable() {
        __rtsan_disable()
    }

    /// Enter real-time context.
    /// When in a real-time context, RTSan interceptors will error if realtime
    /// violations are detected. Calls to this method are injected at the code
    /// generation stage when RTSan is enabled.
    /// corresponds to a [[clang::nonblocking]] attribute.
    public static func realtimeEnter() {
        __rtsan_realtime_enter()
    }

    /// Exit the real-time context.
    /// When not in a real-time context, RTSan interceptors will simply forward
    /// intercepted method calls to the real methods.
    public static func realtimeExit() {
        __rtsan_realtime_exit()
    }

    /// Allows the user to specify a function as not-real-time-safe
    /// Including this in the first line of a function definition is
    /// analogous to marking a function `[[clang::blocking]]`
    public static func notifyBlockingCall(functionName: StaticString) {
        __rtsan_notify_blocking_call(functionName.utf8Start)
    }

    public static func withDisabled(_ execute: () -> Void) {
        disable()
        execute()
        enable()
    }
}
