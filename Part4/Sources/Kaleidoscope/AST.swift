struct Prototype {
    let name: String
    let params: [String]
}

struct Definition {
    let prototype: Prototype
    let expr: Expr
}

class TopLevel {
    private(set) var externs = [Prototype]()
    private(set) var definitions = [Definition]()
    private(set) var prototypeMap = [String: Prototype]()

    init(externs: [Prototype], definitions: [Definition]) {
        externs.forEach(addExtern)
        definitions.forEach(addDefinition)
    }

    func prototype(name: String) -> Prototype? {
        return prototypeMap[name]
    }

    func addExtern(_ prototype: Prototype) {
        self.externs.append(prototype)
        prototypeMap[prototype.name] = prototype
    }

    func addDefinition(_ definition: Definition) {
        self.definitions.append(definition)
        prototypeMap[definition.prototype.name] = definition.prototype
    }
}

indirect enum Expr {
    case number(Double)
    case variable(String)
    case binary(Expr, BinaryOperator, Expr)
    case call(String, [Expr])
}
