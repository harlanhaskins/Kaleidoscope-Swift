import LLVMSwift

enum IRError: Error, CustomStringConvertible {
    case unknownFunction(String)
    case unknownVariable(String)
    case arityMismatch(String, expected: Int, got: Int)

    var description: String {
        switch self {
        case .unknownFunction(let name):
            return "unknown function '\(name)'"
        case .unknownVariable(let name):
            return "unknwon variable '\(name)'"
        case .arityMismatch(let name, let expected, let got):
            return "call to function '\(name)' with \(got) arguments (expected \(expected))"
        }
    }
}

class IRGenerator {
    let module: Module
    let builder: IRBuilder
    let topLevel: TopLevel

    private var varBindings = [String: IRValue]()

    init(topLevel: TopLevel) {
        self.module = Module(name: "main")
        self.builder = IRBuilder(module: module)
        self.topLevel = topLevel
    }

    func emit() throws {
        for definition in topLevel.definitions {
            try emitDefinition(definition)
        }
    }

    func withScope(_ block: () throws -> Void) rethrows {
        let oldBindings = varBindings
        try block()
        varBindings = oldBindings
    }

    @discardableResult
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
        let function = try emitPrototype(definition.prototype)
        try withScope {
            for (idx, arg) in definition.prototype.params.enumerated() {
                let param = function.parameter(at: idx)!
                varBindings[arg] = param
            }
            builder.positionAtEnd(of: function.appendBasicBlock(named: "entry"))
            builder.buildRet(try emitExpr(definition.expr))
        }
        return function
    }

    func emitExpr(_ expr: Expr) throws -> IRValue {
        switch expr {
        case .binary(let lhs, let op, let rhs):
            return try emitBinary(lhs: lhs, op: op, rhs: rhs)
        case .call(let name, let args):
            guard let prototype = topLevel.prototype(name: name) else {
                throw IRError.unknownFunction(name)
            }
            guard prototype.params.count == args.count else {
                throw IRError.arityMismatch(name,
                                            expected: prototype.params.count,
                                            got: args.count)
            }
            let callArgs = try args.map(emitExpr)
            return builder.buildCall(try emitPrototype(prototype), args: callArgs)
        case .variable(let name):
            guard let param = varBindings[name] else {
                throw IRError.unknownVariable(name)
            }
            return param
        case .number(let value):
            return FloatType.double.constant(value)
        }
    }

    func emitBinary(lhs: Expr, op: BinaryOperator, rhs: Expr) throws -> IRValue {
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
        }
    }
}
