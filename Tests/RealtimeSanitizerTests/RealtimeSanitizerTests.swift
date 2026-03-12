import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import RealtimeSanitizer
import RealtimeSanitizerMacros
import rtsan
import Testing
import Synchronization
#if canImport(os)
import os
#endif
import SwiftSyntaxMacrosGenericTestSupport

@Suite(.serialized)
final class RealtimeSanitizerTests {

    @Test
    func testDefaultDEBUGNonBlockingMacroExpansion() throws {
        assertMacroExpansion(
            """
            @NonBlocking
            func callBlocking() { print("test") }
            """,
            expandedSource: """
            func callBlocking() {
                #if DEBUG
                    RealtimeSanitizer.realtimeEnter()
                    defer {
                        RealtimeSanitizer.realtimeExit()
                    }
                #endif
                print("test")
            }
            """,
            macroSpecs: ["NonBlocking": .init(type: NonBlocking.self)],
            failureHandler: { Issue.record("\($0.message)") }
        )
    }

    @Test
    func testDefaultDEBUGBlockingMacroExpansion() throws {
        assertMacroExpansion(
            """
            @Blocking()
            func userBlocking() { print("test") }
            """,
            expandedSource: """
            func userBlocking() {
                #if DEBUG
                    RealtimeSanitizer.notifyBlockingCall(functionName: #function)
                #endif
                print("test")
            }
            """,
            macroSpecs: ["Blocking": .init(type: Blocking.self)],
            failureHandler: { Issue.record("\($0.message)") }
        )
    }

    @Test
    func testCustomConditionNonBlockingMacroExpansion() throws {
        assertMacroExpansion(
            """
            @NonBlocking(in: "CUSTOM")
            func callBlocking() { print("test") }
            """,
            expandedSource: """
            func callBlocking() {
                #if CUSTOM
                    RealtimeSanitizer.realtimeEnter()
                    defer {
                        RealtimeSanitizer.realtimeExit()
                    }
                #endif
                print("test")
            }
            """,
            macroSpecs: ["NonBlocking": .init(type: NonBlocking.self)],
            failureHandler: { Issue.record("\($0.message)") }
        )
    }

    @Test
    func testCustomConditionBlockingMacroExpansion() throws {
        assertMacroExpansion(
            """
            @Blocking(in: "CUSTOM")
            func userBlocking() { print("test") }
            """,
            expandedSource: """
            func userBlocking() {
                #if CUSTOM
                    RealtimeSanitizer.notifyBlockingCall(functionName: #function)
                #endif
                print("test")
            }
            """,
            macroSpecs: ["Blocking": .init(type: Blocking.self)],
            failureHandler: { Issue.record("\($0.message)") }
        )
    }

    @Test
    func testBlockingFunctionMarkedNonBlockingRaisesViolation() async {
        await #expect(processExitsWith: .failure) {
            RealtimeSanitizer.ensureInitialized()
            @NonBlocking
            func callBlocking() { print("asdf") }
            callBlocking()
        }
    }

    @Test
    @available(iOS 18, macOS 15, *)
    func testDetectsMutexLock() async {
        await #expect(processExitsWith: .failure) {
            RealtimeSanitizer.ensureInitialized()
            @NonBlocking
            func callBlocking() {
                let mutex = Mutex(3)
                mutex.withLock { $0 + 1 }
            }
            callBlocking()
        }
    }

    #if canImport(os)
    @Test
    @available(iOS 16, *)
    func testDetectsOSAllocatedUnfairLock() async {
        await #expect(processExitsWith: .failure) {
            RealtimeSanitizer.ensureInitialized()
            @NonBlocking
            func callBlocking() {
                let lock = OSAllocatedUnfairLock(initialState: 3)
                lock.withLock { $0 + 1 }
            }
            callBlocking()
        }
    }
    #endif

    @Test
    func testNonBlockingFunctionMarkedNonBlockingDoesntRaiseViolation() {
        @NonBlocking
        func callNonBlocking() { 1 + 1 }
        callNonBlocking()
    }

    @Test
    func testNotifyBlockingCallRaiseViolation() async {
        await #expect(processExitsWith: .failure) {
            RealtimeSanitizer.ensureInitialized()
            @NonBlocking
            func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }
            userBlocking()
        }
    }

    @Test
    func testNotifyBlockingCallMacroRaiseViolation() async {
        await #expect(processExitsWith: .failure) {
            RealtimeSanitizer.ensureInitialized()
            @Blocking
            func userBlocking() { }

            @NonBlocking
            func callNonBlocking() { userBlocking() }
            callNonBlocking()
        }
    }

    @Test
    func testBlockingCallDoesntRaiseViolationIfNotAnnotated() {
        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }
        userBlocking()
    }

    @Test
    func testBlockingCallRaiseViolationWhenExplicitlyEntered() async {
        await #expect(processExitsWith: .failure) {
            RealtimeSanitizer.ensureInitialized()
            func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }
            RealtimeSanitizer.realtimeEnter()
            userBlocking()
            RealtimeSanitizer.realtimeExit()
        }
    }

    @Test
    func testBlockingCallDoesntRaiseViolationWhenExplicitlyEnteredButDisabled() {
        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }
        RealtimeSanitizer.disable()
        RealtimeSanitizer.realtimeEnter()
        userBlocking()
        RealtimeSanitizer.realtimeExit()
        RealtimeSanitizer.enable()
    }

    @Test
    func testBlockingCallDoesntRaiseViolationWhenCompilationConditionNotActive() {
        @NonBlocking(in: "CUSTOM")
        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }
        userBlocking()
    }

    @Test
    func testBlockingCallRaisesViolationWhenInExplicitDEBUG() async {
        await #expect(processExitsWith: .failure) {
            RealtimeSanitizer.ensureInitialized()
            @NonBlocking(in: "DEBUG")
            func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }
            userBlocking()
        }
    }

    @Test
    func testBlockingCallDoesntRaiseViolationWhenInScopedDisabler() {
        @NonBlocking
        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }
        RealtimeSanitizer.withDisabled {
            userBlocking()
        }
    }
}
