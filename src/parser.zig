const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const l = @import("./lexer.zig");
const tok = @import("./token.zig");
const ast = @import("./ast.zig");

const Program = ast.Program;
const Token = tok.Token;
const TokenType = tok.TokenType;

const Parser = struct {
    const Self = @This();

    lex: l.Lexer,
    allocator: Allocator,

    current_token: Token = Token{ .type_ = .illegal, .literal = "" },
    peek_token: Token = Token{ .type_ = .illegal, .literal = "" },

    errors: ArrayList([]const u8),

    pub fn init(input: []const u8, alloc: Allocator) Self {
        var parser = Self{
            .lex = l.Lexer.init(input),
            .allocator = alloc,
            .errors = ArrayList([]const u8).init(alloc),
        };

        // Read two tokens so that both the current and peek are satisfied
        parser.nextToken();
        parser.nextToken();

        return parser;
    }

    pub fn deinit(self: *Self) void {
        self.errors.deinit();
    }

    pub fn nextToken(self: *Self) void {
        self.current_token = self.peek_token;
        self.peek_token = self.lex.nextToken();
    }

    pub fn parseProgram(self: *Self) !Program {
        var program = Program.init(self.allocator);
        while (self.current_token.type_ != .eof) : (self.nextToken()) {
            if (try self.parseStatement()) |statement| {
                try program.statements.append(statement);
            }
        }

        return program;
    }

    fn parseStatement(self: *Self) !?ast.Statement {
        return switch (self.current_token.type_) {
            .let => try self.parseLetStatement(),
            .@"return" => try self.parseReturnStatement(),
            else => null,
        };
    }

    fn parseLetStatement(self: *Self) !?ast.Statement {
        const current_token = self.current_token;

        if (!try self.expectPeek(.ident)) {
            return null;
        }

        const name = ast.Identifier{
            .token = self.current_token,
            .value = self.current_token.literal,
        };

        if (!try self.expectPeek(.assign)) {
            return null;
        }

        while (!self.currentTokenIs(.semicolon)) {
            self.nextToken();
        }

        const let_stmt = ast.LetStatement{
            .token = current_token,
            .name = name,
        };

        return let_stmt.statement();
    }

    fn parseReturnStatement(self: *Self) !?ast.Statement {
        const return_statement = ast.ReturnStatement{ .token = self.current_token };

        self.nextToken();

        while (!self.currentTokenIs(.semicolon)) {
            self.nextToken();
        }

        return return_statement.statement();
    }

    fn currentTokenIs(self: Self, token_type: TokenType) bool {
        return self.current_token.type_ == token_type;
    }

    fn peekTokenIs(self: Self, token_type: TokenType) bool {
        return self.peek_token.type_ == token_type;
    }

    fn expectPeek(self: *Self, token_type: TokenType) !bool {
        if (self.peekTokenIs(token_type)) {
            self.nextToken();
            return true;
        }

        try self.peekError(token_type);
        return false;
    }

    fn peekError(self: *Self, token_type: TokenType) !void {
        const buf = try std.fmt.allocPrint(
            self.allocator,
            "Expected next token to be {any}, got {any} instead",
            .{ token_type, self.peek_token.type_ },
        );

        try self.errors.append(buf);
    }
};

fn checkParserErrors(parser: Parser) !void {
    for (parser.errors.items) |err| {
        std.log.err("Parser error: {s}", .{err});
    }

    try testing.expectEqual(0, parser.errors.items.len);
}

test "Let Statements" {
    const input =
        \\let x = 5;
        \\let y = 10;
        \\let foobar = 838383;
    ;

    var parser = Parser.init(input, testing.allocator);
    defer parser.deinit();

    var program = try parser.parseProgram();
    defer program.deinit();

    try checkParserErrors(parser);
    try testing.expectEqual(3, program.statements.items.len);

    const tests = [_][]const u8{
        "x",
        "y",
        "foobar",
    };

    for (tests, 0..) |expected, i| {
        const statement = program.statements.items[i];
        try testing.expectEqualStrings("let", statement.tokenLiteral());

        switch (statement) {
            .let => |let_stmt| {
                try testing.expectEqualStrings(expected, let_stmt.name.value);
                try testing.expectEqualStrings(expected, let_stmt.name.tokenLiteral());
            },
            else => return error.IllegalType,
        }
    }
}

test "Return Statements" {
    const input =
        \\return 5;
        \\return 10;
        \\return add(15);
    ;

    var parser = Parser.init(input, testing.allocator);
    defer parser.deinit();

    var program = try parser.parseProgram();
    defer program.deinit();

    try checkParserErrors(parser);
    try testing.expectEqual(3, program.statements.items.len);

    for (program.statements.items) |stmt| {
        switch (stmt) {
            .returns => |ret| {
                try testing.expectEqualStrings("return", ret.tokenLiteral());
                try testing.expectEqual(null, ret.value);
            },
            else => return error.IllegalType,
        }
    }
}
