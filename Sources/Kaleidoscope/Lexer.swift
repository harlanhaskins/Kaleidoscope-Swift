#if os(macOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

enum BinaryOperator: UnicodeScalar {
    case plus = "+"
    case minus = "-"
    case times = "*"
    case divide = "/"
    case mod = "%"
}

enum Token: Equatable {
    case leftParen, rightParen, def, extern, comma, semicolon
    case identifier(String)
    case number(Double)
    case `operator`(BinaryOperator)

    static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.leftParen, .leftParen), (.rightParen, .rightParen),
             (.def, .def), (.extern, .extern), (.comma, .comma),
             (.semicolon, .semicolon):
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

extension UnicodeScalar {
    var isSpace: Bool {
        return isspace(Int32(self.value)) != 0
    }
    var isAlphanumeric: Bool {
        return isalnum(Int32(self.value)) != 0 || self == "_"
    }
}

class Lexer {
    let input: [UnicodeScalar]
    var index = 0

    init(input: String) {
        self.input = Array(input.unicodeScalars)
    }

    var currentChar: UnicodeScalar? {
        return index < input.count ? input[index] : nil
    }

    func advanceIndex() {
        index += 1
    }

    func readIdentifier() -> String {
        var str = ""
        while let char = currentChar, char.isAlphanumeric {
            str.unicodeScalars.append(char)
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
        let singleTokMapping: [UnicodeScalar: Token] = [
            ",": .comma, "(": .leftParen, ")": .rightParen,
            ";": .semicolon, "+": .operator(.plus), "-": .operator(.minus),
            "*": .operator(.times), "/": .operator(.divide),
            "%": .operator(.mod)
        ]

        if let tok = singleTokMapping[char] {
            advanceIndex()
            return tok
        }

        // This is where we parse identifiers or numbers
        // We're going to use Swift's built-in double parsing
        // logic here.
        if char.isAlphanumeric {
            var str = readIdentifier()
            if Int(str) != nil {
                let backtrackIndex = index
                if currentChar == "." {
                    advanceIndex()
                    let decimalStr = readIdentifier()
                    if Int(str) != nil {
                        str.append(".")
                        str += decimalStr
                    } else {
                        index = backtrackIndex
                    }
                }
                return .number(Double(str)!)
            }

            // Look for known tokens, otherwise fall back to
            // the identifier token
            switch str {
            case "def":
                return .def
            case "extern":
                return .extern
            default:
                return .identifier(str)
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
