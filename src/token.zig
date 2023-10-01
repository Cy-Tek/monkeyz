pub const TokenType = enum {
    illegal,
    eof,

    // Identifiers + literals
    ident,
    int,

    // Operators
    assign,
    plus,
    minus,
    bang,
    asterisk,
    slash,

    lt,
    gt,
    eq,
    not_eq,

    // Delimiters
    comma,
    semicolon,

    l_paren,
    r_paren,
    l_brace,
    r_brace,

    // Keywords
    function,
    let,
    @"if",
    @"else",
    @"return",
    true,
    false,

    const TokenTypeTable = [@typeInfo(TokenType).Enum.fields.len][:0]const u8{
        "Illegal",
        "EoF",

        // Identifiers + literals
        "Ident",
        "Int",

        // Operators
        "Assign",
        "Plus",
        "Minus",
        "Bang",
        "Asterisk",
        "Slash",

        "LT",
        "GT",
        "Equal",
        "Not Equal",

        // Delimiters
        "Comma",
        "Semicolon",

        "LParen",
        "RParen",
        "LBrace",
        "RBrace",

        // Keywords
        "Function",
        "Let",
        "If",
        "Else",
        "Return",
        "True",
        "False",
    };

    pub fn str(self: TokenType) [:0]const u8 {
        return TokenTypeTable[@intFromEnum(self)];
    }
};

pub const Token = struct {
    type_: TokenType,
    literal: []const u8,

    pub fn init(token_type: TokenType, literal: []const u8) Token {
        return Token{
            .type_ = token_type,
            .literal = literal,
        };
    }
};
