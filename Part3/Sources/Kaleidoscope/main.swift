import Foundation

guard CommandLine.arguments.count > 1 else {
    print("usage: Kaleidoscope <file>")
    exit(-1)
}

do {
    let file = try String(contentsOfFile: CommandLine.arguments[1])
    let lexer = Lexer(input: file)
    let parser = Parser(tokens: lexer.lex())
    let topLevel = try parser.parseTopLevel()
    let irGen = IRGenerator(topLevel: topLevel)
    try irGen.emit()
    irGen.module.dump()
    try irGen.module.verify()
} catch {
    print("error: \(error)")
}
