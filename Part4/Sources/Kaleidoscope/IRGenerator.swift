import LLVM

enum IRError: Error, CustomStringConvertible {
    case unknownFunction(String)
    case unknownVariable(String)
    case wrongNumberOfArgs(String, expected: Int, got: Int)

    var description: String {
        switch self {
        case .unknownFunction(let name):
            return "unknown function '\(name)'"
        case .unknownVariable(let name):
            return "unknwon variable '\(name)'"
        case .wrongNumberOfArgs(let name, let expected, let got):
            return "call to function '\(name)' with \(got) arguments (expected \(expected))"
        }
    }
}

class IRGenerator {
    let module: Module
    let builder: IRBuilder
    let file: File

    private var parameterValues = [String: IRValue]()

    init(moduleName: String = "main", file: File) {
        self.module = Module(name: moduleName)
        self.builder = IRBuilder(module: module)
        self.file = file
    }

    func emit() throws {
        for extern in file.externs {
            emitPrototype(extern)
        }
        for definition in file.definitions {
            try emitDefinition(definition)
        }
        try emitMain()
    }

    func emitPrintf() -> Function {
        if let function = module.function(named: "printf") { return function }
        let printfType = FunctionType(argTypes: [PointerType(pointee: IntType.int8)],
                                      returnType: IntType.int32,
                                      isVarArg: true)
        return builder.addFunction("printf", type: printfType)
    }

    func emitMain() throws {
        let mainType = FunctionType(argTypes: [], returnType: VoidType())
        let function = builder.addFunction("main", type: mainType)
        let entry = function.appendBasicBlock(named: "entry")
        builder.positionAtEnd(of: entry)

        let formatString = builder.buildGlobalStringPtr("%f\n")
        let printf = emitPrintf()

        for expr in file.expressions {
            let val = try emitExpr(expr)
            _ = builder.buildCall(printf, args: [formatString, val])
        }

        builder.buildRetVoid()
    }

    func createREPLInput(_ expr: Expr, number: Int) throws -> Function {
        let name = "__repl_input_\(number)__"
        let replInputType = FunctionType(argTypes: [],
                                         returnType: FloatType.double)
        let function = builder.addFunction(name, type: replInputType)
        let entry = function.appendBasicBlock(named: "entry")
        builder.positionAtEnd(of: entry)
        builder.buildRet(try emitExpr(expr))
        return function
    }

    func addDefinition(_ definiton: Definition) throws -> Function {
        file.addDefinition(definiton)
        return try emitDefinition(definiton)
    }

    func addExtern(_ prototype: Prototype) throws -> Function {
        file.addExtern(prototype)
        return emitPrototype(prototype)
    }

    @discardableResult // declare double @foo(double %n, double %m)
    func emitPrototype(_ prototype: Prototype) -> Function {
        if let function = module.function(named: prototype.name) {
            return function
        }
        let argTypes = [IRType](repeating: FloatType.double,
                                count: prototype.params.count)
        let funcType = FunctionType(argTypes: argTypes,
                                    returnType: FloatType.double)
        let function = builder.addFunction(prototype.name, type: funcType)

        for (var param, name) in zip(function.parameters, prototype.params) {
            param.name = name
        }

        return function
    }

    @discardableResult
    func emitDefinition(_ definition: Definition) throws -> Function {
        let function = emitPrototype(definition.prototype)

        for (idx, arg) in definition.prototype.params.enumerated() {
            let param = function.parameter(at: idx)!
            parameterValues[arg] = param
        }

        let entryBlock = function.appendBasicBlock(named: "entry")
        builder.positionAtEnd(of: entryBlock)

        let expr = try emitExpr(definition.expr)
        builder.buildRet(expr)

        parameterValues.removeAll()

        return function
    }

    func emitExpr(_ expr: Expr) throws -> IRValue {
        switch expr {
        case .variable(let name):
            guard let param = parameterValues[name] else {
                throw IRError.unknownVariable(name)
            }
            return param
        case .number(let value):
            return FloatType.double.constant(value)
        case .binary(let lhs, let op, let rhs):
            let lhsVal = try emitExpr(lhs)
            let rhsVal = try emitExpr(rhs)
            switch op {
            case .plus:
                return builder.buildAdd(lhsVal, rhsVal)
            case .minus:
                return builder.buildSub(lhsVal, rhsVal)
            case .divide:
                return builder.buildDiv(lhsVal, rhsVal)
            case .times:
                return builder.buildMul(lhsVal, rhsVal)
            case .mod:
                return builder.buildRem(lhsVal, rhsVal)
            case .equals:
                let comparison = builder.buildFCmp(lhsVal, rhsVal, .orderedEqual)
                return builder.buildIntToFP(comparison,
                                            type: FloatType.double,
                                            signed: false)
            }
        case .call(let name, let args):
            guard let prototype = file.prototype(name: name) else {
                throw IRError.unknownFunction(name)
            }
            guard prototype.params.count == args.count else {
                throw IRError.wrongNumberOfArgs(name,
                                            expected: prototype.params.count,
                                            got: args.count)
            }
            let callArgs = try args.map(emitExpr)
            let function = emitPrototype(prototype)
            return builder.buildCall(function, args: callArgs)
        case .ifelse(let cond, let thenExpr, let elseExpr):
            let checkCond = builder.buildFCmp(try emitExpr(cond),
                                              FloatType.double.constant(0.0),
                                              .orderedNotEqual)

            let thenBB = builder.currentFunction!.appendBasicBlock(named: "then")
            let elseBB = builder.currentFunction!.appendBasicBlock(named: "else")
            let mergeBB = builder.currentFunction!.appendBasicBlock(named: "merge")

            builder.buildCondBr(condition: checkCond, then: thenBB, else: elseBB)

            builder.positionAtEnd(of: thenBB)
            let thenVal = try emitExpr(thenExpr)
            builder.buildBr(mergeBB)

            builder.positionAtEnd(of: elseBB)
            let elseVal = try emitExpr(elseExpr)
            builder.buildBr(mergeBB)

            builder.positionAtEnd(of: mergeBB)

            let phi = builder.buildPhi(FloatType.double)
            phi.addIncoming([(thenVal, thenBB), (elseVal, elseBB)])

            return phi
        }
    }
}
