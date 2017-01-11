enum ParseError: Error {
    case unexpectedToken(Token)
    case unexpectedEOF
}

class Parser {
    let tokens: [Token]
    var index = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    var currentToken: Token? {
        return index < tokens.count ? tokens[index] : nil
    }

    func advance(n: Int = 1) {
        index += n
    }

    func parseTopLevel() throws -> TopLevel {
        var externs = [Prototype]()
        var definitions = [Definition]()
        while let tok = currentToken {
            switch tok {
            case .extern:
                externs.append(try parseExtern())
            case .def:
                definitions.append(try parseDefinition())
            default:
                throw ParseError.unexpectedToken(tok)
            }
        }
        return TopLevel(externs: externs, definitions: definitions)
    }

    func parseExpr() throws -> Expr {
        guard let token = currentToken else {
            throw ParseError.unexpectedEOF
        }
        var expr: Expr
        switch token {
        case .leftParen:
            advance()
            expr = try parseExpr()
            try parse(.rightParen)
        case .number(let value):
            advance()
            expr = .number(value)
        case .identifier(let value):
            advance()
            if case .leftParen? = currentToken {
                let params = try parseCommaSeparated(parseExpr)
                expr = .call(value, params)
            } else {
                expr = .variable(value)
            }
        default:
            throw ParseError.unexpectedToken(token)
        }

        if case .operator(let op)? = currentToken {
            advance()
            let rhs = try parseExpr()
            expr = .binary(expr, op, rhs)
        }

        return expr
    }

    func parse(_ token: Token) throws {
        guard let tok = currentToken else {
            throw ParseError.unexpectedEOF
        }
        guard token == tok else {
            throw ParseError.unexpectedToken(token)
        }
        advance()
    }

    func parseIdentifier() throws -> String {
        guard let token = currentToken else {
            throw ParseError.unexpectedEOF
        }
        guard case .identifier(let name) = token else {
            throw ParseError.unexpectedToken(token)
        }
        advance()
        return name
    }

    func parsePrototype() throws -> Prototype {
        let name = try parseIdentifier()
        let params = try parseCommaSeparated(parseIdentifier)
        return Prototype(name: name, params: params)
    }

    func parseCommaSeparated<TermType>(_ parseFn: () throws -> TermType) throws -> [TermType] {
        try parse(.leftParen)
        var vals = [TermType]()
        while let tok = currentToken, tok != .rightParen {
            let val = try parseFn()
            if case .comma? = currentToken {
                try parse(.comma)
            }
            vals.append(val)
        }
        try parse(.rightParen)
        return vals
    }

    func parseExtern() throws -> Prototype {
        try parse(.extern)
        return try parsePrototype()
    }

    func parseDefinition() throws -> Definition {
        try parse(.def)
        let prototype = try parsePrototype()
        let expr = try parseExpr()
        return Definition(prototype: prototype, expr: expr)
    }
}
