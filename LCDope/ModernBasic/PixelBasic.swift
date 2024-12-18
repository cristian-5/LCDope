
import Foundation

enum TokenType: String {
	case string
	case keyword
	case type
	case boolean
	case identifier
	case symbol // operators
	case integer
	case real
	case newline
	case unknown
}

struct Token {
	let type: TokenType
	let lexeme: String
	let index: String.Index
}

class Lexer {

	static private let OPERATORS = "()[]{}+-*/%:=<>^/\\,";
	static private let   LETTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_";
	static private let HEXDIGITS = "0123456789abcdefABCDEF";
	static private let    DIGITS = "0123456789";

	private let input: String
	private var index: String.Index
	
	init(input: String) {
		self.input = input
		self.index = input.startIndex
	}

	/// Check if we have reached the end of input.
	private var isAtEnd: Bool {
		return index >= input.endIndex
	}

	/// Advance the index and return the current character.
	@discardableResult
	private func advance() -> Character {
		let char = input[index]
		index = input.index(after: index)
		return char
	}

	/// Peek at the current character without advancing.
	private func peek() -> Character? {
		return isAtEnd ? nil : input[index]
	}

	/// Match a specific character.
	private func match(_ expected: Character) -> Bool {
		guard let char = peek(), char == expected else {
			return false
		}
		advance()
		return true
	}

	/// Skip whitespace except for newlines.
	private func skipWhitespaceAndComments() {
		while let char = peek() {
			if char == ";" {
				// Skip comment until the end of the line.
				while let commentChar = peek(), !commentChar.isNewline {
					advance()
				}
			} else if char.isWhitespace && !char.isNewline { // do not skip newlines
				advance()
			} else {
				break
			}
		}
	}

	/// Parse a string token, supporting escape sequences and multiline strings.
	private func parseString() -> Token {
		var value = ""
		var isEscaped = false
		while let char = peek() {
			advance()
			if isEscaped {
				switch char {
				case "\"": value.append("\"")
				case "\\": value.append("\\")
				case "n": value.append("\n")
				case "t": value.append("\t")
				case "r": value.append("\r")
				case "u": // parse Unicode escape sequence (e.g., \u{1F600}):
					if match("{") {
						var unicodeValue = ""
						while let unicodeChar = peek(), unicodeChar != "}" {
							unicodeValue.append(advance())
						}
						if match("}") {
							if let scalar = UnicodeScalar(unicodeValue) {
								value.append(Character(scalar))
							} else {
								return Token(type: .unknown, lexeme: value, index: index)
							}
						} else {
							return Token(type: .unknown, lexeme: value, index: index)
						}
					} else {
						return Token(type: .unknown, lexeme: value, index: index)
					}
				default:
					value.append(char) // add the escaped character as-is
				}
				isEscaped = false
			} else if char == "\\" {
				isEscaped = true
			} else if char == "\"" {
				return Token(type: .string, lexeme: value, index: index)
			} else if char.isNewline {
				value.append(char)
			} else {
				value.append(char)
			}
		}
		return Token(type: .unknown, lexeme: value, index: index)
	}

	/// Parse a number (integer or real).
	private func parseNumber() -> Token {
		var value = ""
		var isReal = false
		while let char = peek(), Lexer.DIGITS.contains(char) || char == "." {
			if char == "." {
				if isReal {
					return Token(type: .unknown, lexeme: value, index: index)
				}
				isReal = true
			}
			value.append(advance())
		}
		if isReal {
			return Token(type: .real, lexeme: value, index: index)
		} else {
			return Token(type: .integer, lexeme: value, index: index)
		}
	}

	/// Parse an identifier.
	private func identifier() -> Token {
		var value = ""
		while let char = peek(), Lexer.LETTERS.contains(char) || Lexer.DIGITS.contains(char) {
			value.append(advance())
		}
		let keywords = [ "if", "else", "while", "until", "repeat", "loop", "return", "break", "continue", "end" ];
		let types = [ "natural", "integer", "real", "string", "boolean", "void", "any" ];
		let boolean = [ "true", "false" ]
		if keywords.contains(value) {
			return Token(type: .keyword, lexeme: value, index: index)
		} else if types.contains(value) {
			return Token(type: .type, lexeme: value, index: index)
		} else if boolean.contains(value) {
			return Token(type: .boolean, lexeme: value, index: index)
		}
		return Token(type: .identifier, lexeme: value, index: index)
	}

	/// Get the next token.
	private func nextToken() -> Token? {
		skipWhitespaceAndComments()
		guard let char = peek() else {
			return nil // end of file
		}
		if char == "\"" {
			advance()
			return parseString()
		} else if char == "#" {
			var value = String(advance())
			while let char = peek(), Lexer.HEXDIGITS.contains(char) {
				value.append(advance())
			}
			return Token(type: .integer, lexeme: value, index: index)
		} else if Lexer.DIGITS.contains(char) {
			return parseNumber()
		} else if Lexer.LETTERS.contains(char) {
			return identifier()
		} else if Lexer.OPERATORS.contains(char) {
			var value = ""
			while let char = peek(), Lexer.OPERATORS.contains(char) {
				value.append(advance())
			}
			return Token(type: .symbol, lexeme: value, index: index)
		} else if char.isNewline {
			var value = ""
			while let char = peek(), char.isNewline {
				value.append(advance())
			}
			return Token(type: .newline, lexeme: value, index: index)
		}
		return Token(type: .unknown, lexeme: String(char), index: index)
	}

	/// Tokenize the input into rows of tokens.
	func tokenize() -> [Token] {
		var tokens = [Token]()
		while let token = nextToken() {
			tokens.append(token)
		}
		return tokens
	}
}

struct Program {
	let declarations: [Declaration]
	let functions: [Function]
}

struct LanguageType {
	let token: Token
}

struct Declaration: Statement {
	let identifier: Token
	let type: LanguageType
	let expression: Expression?
}

struct Function {
	let identifier: Token
	let returnType: LanguageType
	let parameters: [Parameter]
	let statements: [Statement]
}

struct Parameter {
	let identifier: Token
	let type: LanguageType
}

protocol Expression {
	
}
struct BinaryExpression: Expression {
	let lhs: Expression
	let op: Token
	let rhs: Expression
}
struct UnaryExpression: Expression {
	let op: Token
	let operand: Expression
}

struct Assignment: Expression {
	let identifiers: [Token]
	let expression: Expression
}

struct Identifier: Expression {
	let token: Token
}

struct Literal: Expression {
	let token: Token
}

protocol Statement { }

struct ExpressionStatement: Statement {
	let expression: Expression
}

struct IfStatement: Statement {
	let condition: Expression
	let thenStatements: [Statement]
	let elseStatements: [Statement]
}

struct CycleStatement: Statement {
	let token: Token
	let head: Bool
	let condition: Expression?
	let statements: [Statement]
}

struct FlowStatement: Statement {
	let token: Token // `break` or `continue`
}

struct ReturnStatement: Statement {
	let token: Token
	let expression: Expression?
}

struct SyntaxError: Error {
	let message: String
}

class Parser {
	
	private let input: String
	private let file: String
	private var tokens: [Token]
	private var index = 0
	
	init(input: String, filename: String) {
		self.input = input
		self.tokens = Lexer(input: input).tokenize()
		self.file = filename
	}
	
	private func syntaxError(_ message: String, _ token: Token) -> SyntaxError {
		var line = 1, i = input.startIndex
		while i < token.index {
			if message[i].isNewline {
				line += 1
			}
			i = input.index(after: i)
		}
		return SyntaxError(message: "[\(file):\(line)] \(message)")
	}
	
	public func parse() throws -> Program {
		return try program()
	}
	
	/// program = {(function | declaration) EOL} EOF;
	private func program() throws -> Program {
		var declarations = [Declaration]()
		var functions = [Function]()
		while !endOfFile() {
			// lookahead ll(k):
			if let t = try? type(), let id = match(.identifier) {
				if peek().type == .symbol, peek().lexeme == "(" {
					functions.append(try function(type: t, identifier: id))
				} else { // global declaration:
					declarations.append(try declaration(type: t, identifier: id))
				}
			} else {
				throw syntaxError("Invalid declaration!", peek())
			}
			try consume(.newline)
		}
		return Program(declarations: declarations, functions: functions)
	}
	
	/// declaration = type identifier ":=" expression;
	private func declaration(type: LanguageType, identifier: Token) throws -> Declaration {
		try consume(.symbol, ":=")
		let exp = try expression()
		return Declaration(identifier: identifier, type: type, expression: exp)
	}
	
	/// function = type identifier "(" [parameters] ")" ":" EOL [statements] "end";
	private func function(type: LanguageType, identifier: Token) throws -> Function {
		try consume(.symbol, "(")
		let parameters = try parameters()
		try consume(.symbol, ")")
		try consume(.symbol, ":")
		try consume(.newline)
		let statements = try statements()
		try consume(.symbol, "end")
		return Function(
			identifier: identifier,
			returnType: type,
			parameters: parameters,
			statements: statements
		)
	}

	/// parameters = parameter {"," parameter};
	private func parameters() throws -> [Parameter] {
		var params: [Parameter] = []
		if typeFollows() {
			params.append(try parameter())
			while (match(.symbol, ",") != nil) {
				params.append(try parameter())
			}
		}
		return params
	}
	
	/// parameter = type identifier;
	private func parameter() throws -> Parameter {
		let paramType = try type()
		let identifierToken = try consume(.identifier)
		return Parameter(identifier: identifierToken, type: paramType)
	}
	
	private func typeFollows() -> Bool {
		let p = peek()
		return p.type == .symbol && "[{".contains(p.lexeme) || p.type == .type
	}

	/// type = basic | '[' basic ']' | '{' basic {":" basic} '}';
	private func type() throws -> LanguageType {
		// TODO: Complex types
		/*if (match(.symbol, "[") != nil) {
			let baseType = basic()
			guard (match(.symbol, "]") != nil) else { fatalError("Expected closing bracket") }
			return .array(baseType)
		} else if (match(.symbol, "{") != nil) {
			let baseType = basic()
			var subTypes: [LanguageType] = [baseType]
			while (match(.symbol, ":") != nil) {
				let nextType = basic()
				subTypes.append(nextType)
			}
			guard (match(.symbol, "}") != nil) else { fatalError("Expected closing brace") }
			return .record(subTypes)
		} else {*/
		return LanguageType(token: try consume(.type))
		//}
	}

	/// statements = {statement};
	private func statements() throws -> [Statement] {
		var stmts: [Statement] = []
		// halting problems during if statements require "else" as a terminal
		// this avoids backtracking issues as it won't need to step back
		while !peek(.keyword, ["end", "else"]) {
			stmts.append(try statement())
		}
		return stmts
	}

	/// statement = declaration | expression | if | cycle | return | break | continue;
	private func statement() throws -> Statement {
		var stm: Statement
		if typeFollows() {
			stm = try declaration(type: try type(), identifier: try consume(.identifier))
		} else if peek(.keyword, "if") {
			stm = try ifStatement()
		} else if peek(.keyword, ["while", "until", "loop", "repeat"]) {
			stm = try cycleStatement()
		} else if peek(.keyword, "return") {
			stm = ReturnStatement(token: advance(), expression: peek(.newline) ? nil : try expression())
		} else if peek(.keyword, ["break", "continue"]) {
			stm = FlowStatement(token: advance())
		} else {
			stm = ExpressionStatement(expression: try expression())
		}
		try consume(.newline)
		return stm
	}

	// if = "if" expression ":" EOL [statements] ["else" ["if" expression] ":" EOL [statements]] "end";
	private func ifStatement() throws -> Statement {
		let token = try consume(.keyword, "if")
		let exp = try expression()
		try consume(.symbol, ":")
		try consume(.newline)
		let then = try statements()
		let otherwise: [Statement]
		if match(.keyword, "else") != nil {
			if peek(.keyword, "if") {
				otherwise = [ try ifStatement() ]
			} else {
				try consume(.symbol, ":")
				otherwise = try statements()
			}
		} else {
			otherwise = []
		}
		try consume(.keyword, "end")
		return IfStatement(condition: exp, thenStatements: then, elseStatements: otherwise)
	}
	
	// cycle = repeat | loop | ("while" | "until") expression ":" EOL [statements] "end";
	// repeat = "repeat" ":" EOL [statements] "until" expression;
	// loop = "loop" ":" EOL [statements] "end";
	private func cycleStatement() throws -> Statement {
		if let token = match(.keyword, ["while", "until" ]) {
			let cond = try expression()
			try consume(.symbol, ":")
			try consume(.newline)
			let body = try statements()
			return CycleStatement(token: token, head: true, condition: cond, statements: body)
		} else if match(.keyword, "repeat") != nil {
			try consume(.symbol, ":")
			try consume(.newline)
			let body = try statements()
			let token = try consume(.keyword, [ "until", "while" ])
			let cond = try expression()
			return CycleStatement(token: token, head: true, condition: cond, statements: body)
		} else if let token = match(.keyword, "loop") {
			let body = try statements()
			return CycleStatement(token: token, head: true, condition: nil, statements: body)
		}
		throw syntaxError("Invalid cycle statement!", peek()) // unreachable anyways
	}

	/// expression = assignment | shortOr;
	private func expression() throws -> Expression {
		if peek(.identifier) {
			let id = advance()
			if let eq = match(.symbol, ":=") {
				return try assignment(identifier: id, equals: eq)
			} else {
				stepBack() // backtracking
			}
		}
		return try shortOr()
	}

	/// assignment = identifier {":=" shortOr};
	private func assignment(identifier: Token, equals: Token) throws -> Expression {
		var ids = [identifier]
		while let id = match(.identifier) {
			ids.append(id)
		}
		let exp = try shortOr()
		return Assignment(identifiers: ids, expression: exp)
	}

	/// shortOr = shortAnd {"\\/" shortAnd};
	private func shortOr() throws -> Expression {
		var exp = try shortAnd()
		while let op = match(.symbol, "\\/") {
			exp = BinaryExpression(lhs: exp, op: op, rhs: try shortAnd())
		}
		return exp
	}
	
	/// shortAnd = equality {"/\\" equality};
	private func shortAnd() throws -> Expression {
		var exp = try equality()
		while let op = match(.symbol, "/\\") {
			exp = BinaryExpression(lhs: exp, op: op, rhs: try equality())
		}
		return exp
	}

	/// equality = relational {("=" | "<>") relational};
	private func equality() throws -> Expression {
		var exp = try relational()
		while let op = match(.symbol, ["=", "<>"]) {
			exp = BinaryExpression(lhs: exp, op: op, rhs: try relational())
		}
		return exp
	}
	
	/// relational = additive {("<" | "<=" | ">" | ">=") additive};
	private func relational() throws -> Expression {
		var exp = try additive()
		while let op = match(.symbol, ["<", "<=", ">", ">="]) {
			exp = BinaryExpression(lhs: exp, op: op, rhs: try additive())
		}
		return exp
	}
	
	/// additive = multiplicative {("+" | "-") multiplicative};
	private func additive() throws -> Expression {
		var exp = try multiplicative()
		while let op = match(.symbol, ["+", "-"]) {
			exp = BinaryExpression(lhs: exp, op: op, rhs: try multiplicative())
		}
		return exp
	}
	
	/// multiplicative = unary {("\*" | "/" | "%", "^") unary};
	private func multiplicative() throws -> Expression {
		var exp = try unary()
		while let op = match(.symbol, ["*", "/", "%", "^"]) {
			exp = BinaryExpression(lhs: exp, op: op, rhs: try unary())
		}
		return exp
	}
	
	/// unary = ["+" | "-" | "~"] unary | primary;
	private func unary() throws -> Expression {
		if let op = match(.symbol, ["+", "-", "~"]) {
			return UnaryExpression(op: op, operand: try unary())
		} else {
			return try primary()
		}
	}
	
	/// primary = identifier | constant | "(" expression ")";
	private func primary() throws -> Expression {
		if let id = match(.identifier) {
			return Identifier(token: id)
		} else if (match(.symbol, "(") != nil) {
			let exp = try expression()
			try consume(.symbol, ")")
			return exp
		} else if let t = match([.integer, .real, .string, .boolean]) {
			return Literal(token: t)
		}
		throw syntaxError("Unexpected Token '\(peek().lexeme)'!", peek())
	}

	private func match(_ tokenType: TokenType) -> Token? {
		if peek(tokenType) {
			return advance()
		}
		return nil
	}
	private func match(_ tokenTypes: [TokenType]) -> Token? {
		if tokenTypes.contains(peek().type) {
			return advance()
		}
		return nil
	}
	private func match(_ tokenType: TokenType, _ lexeme: String) -> Token? {
		if peek(tokenType, lexeme) {
			return advance()
		}
		return nil
	}
	private func match(_ tokenType: TokenType, _ lexemes: [String]) -> Token? {
		let current = peek()
		if current.type == tokenType && lexemes.contains(current.lexeme) {
			return advance()
		}
		return nil
	}
	
	@discardableResult
	private func consume(_ tokenType: TokenType) throws -> Token {
		let consumed = match(tokenType)
		if consumed == nil {
			let p = peek()
			throw syntaxError("Expected '\(tokenType.rawValue)' but found '\(p.type.rawValue)' instead!", p)
		}
		return consumed!
	}
	@discardableResult
	private func consume(_ tokenType: TokenType, _ lexeme: String) throws -> Token {
		let consumed = match(tokenType, lexeme)
		if consumed == nil {
			let p = peek()
			throw syntaxError("Expected '\(lexeme)' but found '\(p.lexeme)' instead!", p)
		}
		return consumed!
	}
	@discardableResult
	private func consume(_ tokenType: TokenType, _ lexemes: [String]) throws -> Token {
		let consumed = match(tokenType, lexemes)
		if consumed == nil {
			let p = peek()
			throw syntaxError("Found unexpected token '\(p.lexeme)'!", p)
		}
		return consumed!
	}
	
	private func peek() -> Token {
		return tokens[index]
	}
	private func peek(_ tokenType: TokenType) -> Bool {
		return peek().type == tokenType
	}
	private func peek(_ tokenType: TokenType, _ lexeme: String) -> Bool {
		let current = peek()
		return current.type == tokenType && current.lexeme == lexeme
	}
	private func peek(_ tokenType: TokenType, _ lexemes: [String]) -> Bool {
		let current = peek()
		return current.type == tokenType && lexemes.contains(current.lexeme)
	}
	
	private func advance() -> Token {
		index += 1
		return tokens[index]
	}

	private func stepBack() {
		index = max(0, index - 1)
	}
	
	private func endOfFile() -> Bool {
		return index >= tokens.count
	}

}
