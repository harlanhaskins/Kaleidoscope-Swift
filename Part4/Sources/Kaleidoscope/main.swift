import Foundation
import LLVM

extension String: Error {}

typealias KSMainFunction = @convention(c) () -> Void

do {
    guard CommandLine.arguments.count > 1 else {
        throw "usage: kaleidoscope <file>"
    }

    let input = try String(contentsOfFile: CommandLine.arguments[1])
    let toks = Lexer(input: input).lex()
    let topLevel = try Parser(tokens: toks).parseTopLevel()
    let irGen = IRGenerator(topLevel: topLevel)
    try irGen.emit()
    try irGen.module.verify()
    print(irGen.module)

} catch {
    print("error: \(error)")
    exit(-1)
}
