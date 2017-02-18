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

    func consumeToken(n: Int = 1) {
        index += n
    }

    func parseFile() throws -> File {
        let file = File()
        while let tok = currentToken {
            switch tok {
            case .extern:
                file.addExtern(try parseExtern())
            case .def:
                file.addDefinition(try parseDefinition())
            default:
                let expr = try parseExpr()
                try consume(.semicolon)
                file.addExpression(expr)
            }
        }
        return file
    }

    func parseExpr() throws -> Expr {
        guard let token = currentToken else {
            throw ParseError.unexpectedEOF
        }
        var expr: Expr
        switch token {
        case .leftParen: // ( <expr> )
            consumeToken()
            expr = try parseExpr()
            try consume(.rightParen)
        case .number(let value):
            consumeToken()
            expr = .number(value)
        case .identifier(let value):
            consumeToken()
            if case .leftParen? = currentToken {
                let params = try parseCommaSeparated(parseExpr)
                expr = .call(value, params)
            } else {
                expr = .variable(value)
            }
        case .if: // if <expr> then <expr> else <expr>
            consumeToken()
            let cond = try parseExpr()
            try consume(.then)
            let thenVal = try parseExpr()
            try consume(.else)
            let elseVal = try parseExpr()
            expr = .ifelse(cond, thenVal, elseVal)
        default:
            throw ParseError.unexpectedToken(token)
        }

        if case .operator(let op)? = currentToken {
            consumeToken()
            let rhs = try parseExpr()
            expr = .binary(expr, op, rhs)
        }

        return expr
    }

    func consume(_ token: Token) throws {
        guard let tok = currentToken else {
            throw ParseError.unexpectedEOF
        }
        guard token == tok else {
            throw ParseError.unexpectedToken(token)
        }
        consumeToken()
    }

    func parseIdentifier() throws -> String {
        guard let token = currentToken else {
            throw ParseError.unexpectedEOF
        }
        guard case .identifier(let name) = token else {
            throw ParseError.unexpectedToken(token)
        }
        consumeToken()
        return name
    }

    func parsePrototype() throws -> Prototype {
        let name = try parseIdentifier()
        let params = try parseCommaSeparated(parseIdentifier)
        return Prototype(name: name, params: params)
    }

    func parseCommaSeparated<TermType>(_ parseFn: () throws -> TermType) throws -> [TermType] {
        try consume(.leftParen)
        var vals = [TermType]()
        while let tok = currentToken, tok != .rightParen {
            let val = try parseFn()
            if case .comma? = currentToken {
                try consume(.comma)
            }
            vals.append(val)
        }
        try consume(.rightParen)
        return vals
    }

    func parseExtern() throws -> Prototype {
        try consume(.extern)
        let proto = try parsePrototype()
        try consume(.semicolon)
        return proto
    }

    func parseDefinition() throws -> Definition {
        try consume(.def)
        let prototype = try parsePrototype()
        let expr = try parseExpr()
        let def = Definition(prototype: prototype, expr: expr)
        try consume(.semicolon)
        return def
    }
}
