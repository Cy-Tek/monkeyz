const std = @import("std");
const token = @import("token.zig");
const TokenType = token.TokenType;
const Token = token.Token;

const keywords = std.ComptimeStringMap(TokenType, .{
    .{ "fn", .function },
    .{ "let", .let },
    .{ "if", .@"if" },
    .{ "else", .@"else" },
    .{ "return", .@"return" },
    .{ "true", .true },
    .{ "false", .false },
});

pub const Lexer = struct {
    const Self = @This();

    input: []const u8,
    position: usize = 0,
    read_position: usize = 0,
    ch: u8 = 0,

    pub fn init(text: []const u8) Lexer {
        var l = Lexer{ .input = text };
        l.readChar();

        return l;
    }

    pub fn readChar(self: *Self) void {
        if (self.read_position >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_position];
        }

        self.position = self.read_position;
        self.read_position += 1;
    }

    pub fn nextToken(self: *Self) Token {
        self.skipWhitespace();

        const tok = switch (self.ch) {
            '=' => Token.init(.assign, self.currentSlice(1)),
            '+' => Token.init(.plus, self.currentSlice(1)),
            '-' => Token.init(.minus, self.currentSlice(1)),
            '!' => Token.init(.bang, self.currentSlice(1)),
            '/' => Token.init(.slash, self.currentSlice(1)),
            '*' => Token.init(.asterisk, self.currentSlice(1)),
            '<' => Token.init(.lt, self.currentSlice(1)),
            '>' => Token.init(.gt, self.currentSlice(1)),
            '(' => Token.init(.l_paren, self.currentSlice(1)),
            ')' => Token.init(.r_paren, self.currentSlice(1)),
            '{' => Token.init(.l_brace, self.currentSlice(1)),
            '}' => Token.init(.r_brace, self.currentSlice(1)),
            ',' => Token.init(.comma, self.currentSlice(1)),
            ';' => Token.init(.semicolon, self.currentSlice(1)),
            0 => Token.init(.eof, ""),
            else => blk: {
                if (std.ascii.isAlphabetic(self.ch)) {
                    const literal = self.readIdentifier();
                    const token_type = Self.lookupIdent(literal);
                    return Token.init(token_type, literal);
                }

                if (std.ascii.isDigit(self.ch)) {
                    const int_literal = self.readNumber();
                    return Token.init(.int, int_literal);
                }

                break :blk Token.init(.illegal, "");
            },
        };

        self.readChar();
        return tok;
    }

    fn readIdentifier(self: *Self) []const u8 {
        const position = self.position;
        while (std.ascii.isAlphabetic(self.ch)) {
            self.readChar();
        }

        return self.input[position..self.position];
    }

    fn lookupIdent(ident: []const u8) TokenType {
        if (keywords.get(ident)) |val| {
            return val;
        }

        return .ident;
    }

    fn readNumber(self: *Self) []const u8 {
        const position = self.position;
        while (std.ascii.isDigit(self.ch)) {
            self.readChar();
        }

        return self.input[position..self.position];
    }

    fn skipWhitespace(self: *Self) void {
        while (std.ascii.isWhitespace(self.ch)) {
            self.readChar();
        }
    }

    fn currentSlice(self: *Self, num_of_chars: usize) []const u8 {
        return self.input[self.position .. self.position + num_of_chars];
    }

    test "Current Slice" {
        const input = "hello world";
        var l = Lexer.init(input);

        try std.testing.expectEqualStrings("hello", l.currentSlice(5));
        try std.testing.expectEqualStrings("h", l.currentSlice(1));
        try std.testing.expectEqualStrings("", l.currentSlice(0));

        _ = l.readChar();
        try std.testing.expectEqualStrings("ello ", l.currentSlice(5));
    }
};

test "Next Token" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\
        \\if (5 < 10) {
        \\    return true;
        \\} else {
        \\    return false;
        \\}
    ;

    const tests = [_]Token{
        Token.init(.let, "let"),
        Token.init(.ident, "five"),
        Token.init(.assign, "="),
        Token.init(.int, "5"),
        Token.init(.semicolon, ";"),

        Token.init(.let, "let"),
        Token.init(.ident, "ten"),
        Token.init(.assign, "="),
        Token.init(.int, "10"),
        Token.init(.semicolon, ";"),

        Token.init(.let, "let"),
        Token.init(.ident, "add"),
        Token.init(.assign, "="),
        Token.init(.function, "fn"),
        Token.init(.l_paren, "("),
        Token.init(.ident, "x"),
        Token.init(.comma, ","),
        Token.init(.ident, "y"),
        Token.init(.r_paren, ")"),
        Token.init(.l_brace, "{"),

        Token.init(.ident, "x"),
        Token.init(.plus, "+"),
        Token.init(.ident, "y"),
        Token.init(.semicolon, ";"),

        Token.init(.r_brace, "}"),
        Token.init(.semicolon, ";"),

        Token.init(.let, "let"),
        Token.init(.ident, "result"),
        Token.init(.assign, "="),
        Token.init(.ident, "add"),
        Token.init(.l_paren, "("),
        Token.init(.ident, "five"),
        Token.init(.comma, ","),
        Token.init(.ident, "ten"),
        Token.init(.r_paren, ")"),
        Token.init(.semicolon, ";"),

        Token.init(.bang, "!"),
        Token.init(.minus, "-"),
        Token.init(.slash, "/"),
        Token.init(.asterisk, "*"),
        Token.init(.int, "5"),
        Token.init(.semicolon, ";"),

        Token.init(.int, "5"),
        Token.init(.lt, "<"),
        Token.init(.int, "10"),
        Token.init(.gt, ">"),
        Token.init(.int, "5"),
        Token.init(.semicolon, ";"),

        Token.init(.@"if", "if"),
        Token.init(.l_paren, "("),
        Token.init(.int, "5"),
        Token.init(.lt, "<"),
        Token.init(.int, "10"),
        Token.init(.r_paren, ")"),
        Token.init(.l_brace, "{"),
        Token.init(.@"return", "return"),
        Token.init(.true, "true"),
        Token.init(.semicolon, ";"),
        Token.init(.r_brace, "}"),
        Token.init(.@"else", "else"),
        Token.init(.l_brace, "{"),
        Token.init(.@"return", "return"),
        Token.init(.false, "false"),
        Token.init(.semicolon, ";"),
        Token.init(.r_brace, "}"),

        Token.init(.eof, ""),
    };

    var lexer = Lexer.init(input);

    for (tests) |expected| {
        const t = lexer.nextToken();

        try std.testing.expectEqualStrings(expected.literal, t.literal);
        try std.testing.expectEqual(expected.type_, t.type_);
    }
}
