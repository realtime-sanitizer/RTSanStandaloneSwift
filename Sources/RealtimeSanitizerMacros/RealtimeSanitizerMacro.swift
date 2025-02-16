import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `NonBlocking` macro.
/// A body of a function annotated with `NonBlocking` macro
/// will be wrapped inside `__rtsan_realtime_enter` and `__rtsan_realtime_exit` calls.
/// For example:
///
///     @NonBlocking
///     func process() { print("") }
///
///  will expand to
///
///     func process() {
///         RealtimeSanitizer.realtimeEnter()
///         defer { RealtimeSanitizer.realtimeExit() }
///         print("")
///     }
public struct NonBlocking: BodyMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingBodyFor declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.CodeBlockItemSyntax] {
        let body = try ensureFunctionWithBody(declaration: declaration)
        let condition = try extractCompilationCondition(node: node)

        return [
            """
            #if \(ExprSyntax(stringLiteral: condition))
                RealtimeSanitizer.realtimeEnter()
                defer {
                    RealtimeSanitizer.realtimeExit()
                }
            #endif
            """
        ] + body.statements
    }
}

/// Implementation of the `Blocking` macro.
/// A body of a function annotated with `Blocking` macro
/// will invoke `__rtsan_notify_blocking_call`, and
/// allow RTSan to catch user specified violation.
public struct Blocking: BodyMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingBodyFor declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.CodeBlockItemSyntax] {
        let body = try ensureFunctionWithBody(declaration: declaration)
        let condition = try extractCompilationCondition(node: node)

        return [
            """
            #if \(ExprSyntax(stringLiteral: condition))
                RealtimeSanitizer.notifyBlockingCall(functionName: #function)
            #endif
            """
        ] + body.statements
    }
}

private func ensureFunctionWithBody(declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax) throws -> CodeBlockSyntax {
    guard let function = declaration.as(FunctionDeclSyntax.self), let body = function.body else {
        throw MacroExpansionErrorMessage("expected a function with a body")
    }
    return body
}
private func extractCompilationCondition(node: SwiftSyntax.AttributeSyntax) throws -> String {
    if case let .argumentList(arguments) = node.arguments, let argument = arguments.first {
        guard let stringArgument = StringLiteralExprSyntax(argument.expression) else {
            throw MacroExpansionErrorMessage("The macro argument is not a string")
        }
        guard let argumentLiteral = stringArgument.representedLiteralValue else {
            throw MacroExpansionErrorMessage("The macro argument is not a string literal")
        }
        return argumentLiteral
    }
    return "DEBUG"
}

@main
struct RealtimeSanitizerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [NonBlocking.self, Blocking.self]
}
