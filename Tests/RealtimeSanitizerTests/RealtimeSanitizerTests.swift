import SwiftSyntax
import Foundation
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
#if canImport(SwiftGlibc)
@preconcurrency import SwiftGlibc
#endif
import SwiftSyntaxMacrosGenericTestSupport

@Suite(.serialized)
final class RealtimeSanitizerTests {

    init() {
        RealtimeSanitizer.ensureInitialized()
    }

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
    func testBlockingFunctionMarkedNonBlockingRaisesViolation() async throws {
        @NonBlocking
        func callBlocking() { print("asdf") }

        await confirmation { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            callBlocking()
        }
    }

    @Test
    @available(iOS 18, macOS 15, *)
    func testDetectsMutexLock() async throws {
        @NonBlocking
        func callBlocking() {
            let mutex = Mutex(3)
            mutex.withLock { $0 + 1 }
        }

        await confirmation { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            callBlocking()
        }
    }

    #if canImport(os)
    @Test
    @available(iOS 16, *)
    func testDetectsOSAllocatedUnfairLock() async throws {
        @NonBlocking
        func callBlocking() {
            let lock = OSAllocatedUnfairLock(initialState: 3)
            lock.withLock { $0 + 1 }
        }

        await confirmation { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            callBlocking()
        }
    }
    #endif
    @Test
    func testNonBlockingFunctionMarkedNonBlockingDoesntRaiseViolation() async throws {
        @NonBlocking
        func callNonBlocking() { 1 + 1 }

        await confirmation(expectedCount: 0) { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            callNonBlocking()
        }
    }

    @Test
    func testNotifyBlockingCallRaiseViolation() async throws {

        @NonBlocking
        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }

        await confirmation() { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            userBlocking()
        }
    }

    @Test
    func testNotifyBlockingCallMacroRaiseViolation() async throws {

        @Blocking
        func userBlocking() { }

        @NonBlocking
        func callNonBlocking() { userBlocking() }

        await confirmation() { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            callNonBlocking()
        }
    }

    @Test
    func testBlockingCallDoesntRaiseViolationIfNotAnnotated() async throws {

        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }

        await confirmation(expectedCount: 0) { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            userBlocking()
        }
    }

    @Test
    func testBlockingCallRaiseViolationWhenExplicitlyEntered() async throws {

        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }

        await confirmation() { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            RealtimeSanitizer.realtimeEnter()
            userBlocking()
            RealtimeSanitizer.realtimeExit()
        }
    }

    @Test
    func testBlockingCallDoesntRaiseViolationWhenExplicitlyEnteredButDisabled() async throws {

        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }

        await confirmation(expectedCount: 0) { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            RealtimeSanitizer.disable()
            RealtimeSanitizer.realtimeEnter()
            userBlocking()
            RealtimeSanitizer.realtimeExit()
            RealtimeSanitizer.enable()
        }
    }

    @Test
    func testBlockingCallDoesntRaiseViolationWhenCompilationConditionNotActive() async throws {

        @NonBlocking(in: "CUSTOM")
        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }

        await confirmation(expectedCount: 0) { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            userBlocking()
        }
    }

    @Test
    func testBlockingCallRaisesViolationWhenInExplicitDEBUG() async throws {

        @NonBlocking(in: "DEBUG")
        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }

        await confirmation(expectedCount: 1) { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            userBlocking()
        }
    }

    @Test
    func testBlockingCallDoesntRaiseViolationWhenInScopedDisabler() async throws {

        @NonBlocking
        func userBlocking() { RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking") }

        await confirmation(expectedCount: 0) { confirmation in
            listenForUnsafeCall { confirmation.confirm() }
            RealtimeSanitizer.withDisabled {
                userBlocking()
            }
        }
    }
}

// extern "C" void __sanitizer_set_death_callback(void (*callback)(void));
@_extern(c, "__sanitizer_set_death_callback")
func setDeathCallback(_ callback: @convention(c) () -> Void) -> Void

func listenForUnsafeCall(onDetect: @Sendable @escaping () -> Void) {
    let outPipe = Pipe()
    let savedStderr = dup(STDERR_FILENO)
    outPipe.fileHandleForReading.readabilityHandler = { fileHandle in
        let data = fileHandle.availableData
        if data.isEmpty {
            fileHandle.readabilityHandler = nil
        }
        if let str = String(data: data,  encoding: .utf8) {
            if str.contains("unsafe-library-call") || str.contains("blocking-call") {
                fileHandle.readabilityHandler = nil
                dup2(savedStderr, STDERR_FILENO)
                try! outPipe.fileHandleForWriting.close()
                close(savedStderr)
                print(str)
                onDetect()
            }
        }
    }
    setvbuf(stderr, nil, _IONBF, 0)
    dup2(outPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
}
