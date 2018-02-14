#if os(macOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

enum BinaryOperator: Character {
    case plus = "+", minus = "-",
         times = "*", divide = "/",
         mod = "%", equals = "="
}

enum Token: Equatable {
    case leftParen, rightParen, def, extern, comma, semicolon, `if`, then, `else`
    case identifier(String)
    case number(Double)
    case `operator`(BinaryOperator)

    static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.leftParen, .leftParen), (.rightParen, .rightParen),
             (.def, .def), (.extern, .extern), (.comma, .comma),
             (.semicolon, .semicolon), (.if, .if), (.then, .then),
             (.else, .else):
            return true
        case let (.identifier(id1), .identifier(id2)):
            return id1 == id2
        case let (.number(n1), .number(n2)):
            return n1 == n2
        case let (.operator(op1), .operator(op2)):
            return op1 == op2
        default:
            return false
        }
    }
}

extension Character {
    var value: Int32 {
        return Int32(String(self).unicodeScalars.first!.value)
    }
    var isSpace: Bool {
        return isspace(value) != 0
    }
    var isAlphanumeric: Bool {
        return isalnum(value) != 0 || self == "_"
    }
}

class Lexer {
    let input: String
    var index: String.Index

    init(input: String) {
        self.input = input
        self.index = input.startIndex
    }

    var currentChar: Character? {
        return index < input.endIndex ? input[index] : nil
    }

    func advanceIndex() {
        input.formIndex(after: &index)
    }

    func readIdentifierOrNumber() -> String {
        var str = ""
        while let char = currentChar, char.isAlphanumeric || char == "." {
            str.append(char)
            advanceIndex()
        }
        return str
    }

    func advanceToNextToken() -> Token? {
        // Skip all spaces until a non-space token
        while let char = currentChar, char.isSpace {
            advanceIndex()
        }
        // If we hit the end of the input, then we're done
        guard let char = currentChar else {
            return nil
        }

        // Handle single-scalar tokens, like comma,
        // leftParen, rightParen, and the operators
        let singleTokMapping: [Character: Token] = [
            ",": .comma, "(": .leftParen, ")": .rightParen,
            ";": .semicolon, "+": .operator(.plus), "-": .operator(.minus),
            "*": .operator(.times), "/": .operator(.divide),
            "%": .operator(.mod), "=": .operator(.equals)
        ]

        if let tok = singleTokMapping[char] {
            advanceIndex()
            return tok
        }

        // This is where we parse identifiers or numbers
        // We're going to use Swift's built-in double parsing
        // logic here.
        if char.isAlphanumeric {
            let str = readIdentifierOrNumber()

            if let dbl = Double(str) {
                return .number(dbl)
            }

            // Look for known tokens, otherwise fall back to
            // the identifier token
            switch str {
            case "def": return .def
            case "extern": return .extern
            case "if": return .if
            case "then": return .then
            case "else": return .else
            default: return .identifier(str)
            }
        }
        return nil
    }

    func lex() -> [Token] {
        var toks = [Token]()
        while let tok = advanceToNextToken() {
            toks.append(tok)
        }
        return toks
    }
}
