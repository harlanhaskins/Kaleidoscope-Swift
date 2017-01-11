struct Prototype {
    let name: String
    let params: [String]
}

struct Definition {
    let prototype: Prototype
    let expr: Expr
}

struct TopLevel {
    let externs: [Prototype]
    let definitions: [Definition]
    private let prototypeMap: [String: Prototype]

    init(externs: [Prototype], definitions: [Definition]) {
        self.externs = externs
        self.definitions = definitions
        var map = [String: Prototype]()
        let allPrototypes = externs + definitions.map { $0.prototype }
        for prototype in allPrototypes {
            map[prototype.name] = prototype
        }
        self.prototypeMap = map
    }

    func prototype(name: String) -> Prototype? {
        return prototypeMap[name]
    }
}

indirect enum Expr {
    case number(Double)
    case variable(String)
    case binary(Expr, BinaryOperator, Expr)
    case call(String, [Expr])
}
