const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

const l = @import("./lexer.zig");
const tok = @import("./token.zig");
const ast = @import("./ast.zig");

const Program = ast.Program;
const Token = tok.Token;

const Parser = struct {
    const Self = @This();

    lex: *l.Lexer,
    allocator: Allocator,

    current_token: Token = Token{ .type_ = .illegal, .literal = "" },
    peek_token: Token = Token{ .type_ = .illegal, .literal = "" },

    pub fn init(lexer: *l.Lexer, alloc: Allocator) Self {
        var parser = Self{ .lex = lexer, .allocator = alloc };

        // Read two tokens so that both the current and peek are satisfied
        parser.nextToken();
        parser.nextToken();

        return parser;
    }

    pub fn nextToken(self: *Self) void {
        self.current_token = self.peek_token;
        self.peek_token = self.lex.nextToken();
    }

    pub fn parseProgram(self: *Self) !Program {
        var program = Program.init(self.allocator);
        while (self.current_token.type_ != .eof) : (self.nextToken()) {
            if (self.parseStatement()) |statement| {
                program.statements.append(statement);
            }
        }

        return program;
    }

    fn parseStatement(self: *Self) ?ast.Statement {
        return switch (self.current_token.type_) {
            .let => self.parseLetStatement(),
            else => null,
        };
    }

    fn parseLetStatement(self: *Self) ?ast.LetStatement {
        _ = self;
        return null;
    }
};

test "Let Statements" {
    const input =
        \\let x = 5;
        \\let y = 10;
        \\let foobar = 838383;
    ;

    var lex = l.Lexer.init(input);
    var parser = Parser.init(&lex, testing.allocator);

    var program = try parser.parseProgram();
    defer program.deinit();

    try testing.expectEqual(@as(usize, 3), program.statements.len);

    const tests = [_][]const u8{
        "x",
        "y",
        "foobar",
    };

    for (tests, 0..) |expected, i| {
        const statement = program.statements[i];
        try testing.expectEqualStrings("let", statement.tokenLiteral());
        try testing.expectEqualStrings(expected, statement.identifier.value);

        switch (statement) {
            .let => |let_stmt| {
                try testing.expectEqualStrings(expected, let_stmt.name.value);
                try testing.expectEqualStrings(expected, let_stmt.name.token.literal);
            },
            else => return error.IllegalType,
        }
    }
}
