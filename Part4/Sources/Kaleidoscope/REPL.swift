import LLVM

class REPL {
    let irGen: IRGenerator
    let targetMachine: TargetMachine
    let jit: JIT

    typealias KaleidoscopeFnPtr = @convention(c) () -> Double

    init() throws {
        self.irGen = IRGenerator(topLevel: TopLevel())
        self.targetMachine = try TargetMachine()
        self.jit = try JIT(module: irGen.module,
                           machine: self.targetMachine)
    }

    func handleExtern(parser: Parser) throws {
        let extern = try parser.parseExtern()
        let function = try irGen.addExtern(extern)
        print("Read extern:")
        function.dump()
    }

    func handleDefinition(parser: Parser) throws {
        let def = try parser.parseDefinition()
        let function = try irGen.addDefinition(def)
        print("Read definition:")
        function.dump()
    }

    func handleTopLevelExpression(parser: Parser, number: Int) throws {
        let expr = try parser.parseExpr()
        let newIRGen = IRGenerator(moduleName: "__anonymous_\(number)__",
                                   topLevel: irGen.topLevel)
        let function = try newIRGen.createREPLInput(expr,
                                                    number: number)
        jit.addModule(newIRGen.module)
        let functionAddress = jit.addressOfFunction(name: function.name)!
        let fnPtr = unsafeBitCast(functionAddress,
                                  to: KaleidoscopeFnPtr.self)
        print("\(fnPtr())")
        try jit.removeModule(newIRGen.module)
    }

    func run() {
        var expressionsHandled = 0
        while true {
            print("ready> ", terminator: "")
            guard let line = readLine() else {
                continue
            }
            do {
                let lexer = Lexer(input: line)
                let tokens = lexer.lex()
                let parser = Parser(tokens: tokens)
                switch tokens.first {
                case .def?:
                    try handleDefinition(parser: parser)
                case .extern?:
                    try handleExtern(parser: parser)
                case nil:
                    continue
                default:
                    try handleTopLevelExpression(parser: parser,
                                                 number: expressionsHandled)
                    expressionsHandled += 1
                }
            } catch {
                print("error: \(error)")
            }
        }
    }
}
