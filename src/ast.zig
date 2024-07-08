const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Token = @import("token.zig").Token;

//  ── Node ────────────────────────────────────────────────────────────

pub const NodeTag = enum {
    program,
    statement,
    expression,
};

pub const Node = union(NodeTag) {
    program: Program,
    statement: Statement,
    expression: Expression,

    pub fn tokenLiteral(self: @This()) []const u8 {
        return switch (self) {
            .program => |val| val.tokenLiteral(),
            .statement => |statement| statement.tokenLiteral(),
            .expression => |expression| expression.tokenLiteral(),
        };
    }

    pub fn string(self: @This(), writer: anytype) !void {
        switch (self) {
            inline else => |val| try val.string(writer),
        }
    }
};

pub const Program = struct {
    const Self = @This();

    allocator: Allocator,
    statements: ArrayList(Statement),

    pub fn init(alloc: Allocator) Self {
        return Self{
            .allocator = alloc,
            .statements = ArrayList(Statement).init(alloc),
        };
    }

    pub fn deinit(self: *Self) void {
        self.statements.deinit();
    }

    pub fn addStatement(self: *Self, statement: Statement) !void {
        try self.statements.append(statement);
    }

    pub fn tokenLiteral(self: Self) []const u8 {
        return if (self.statements.len > 0)
            self.statements[0].tokenLiteral()
        else
            "";
    }

    pub fn string(self: Self, writer: anytype) !void {
        for (self.statements.items) |statement| {
            try statement.string(writer);
        }
    }
};

//  ── Statements ──────────────────────────────────────────────────────

pub const StatementTag = enum {
    let,
    @"return",
    expression,
};

pub const Statement = union(StatementTag) {
    const Self = @This();

    let: LetStatement,
    @"return": ReturnStatement,
    expression: ExpressionStatement,

    pub fn tokenLiteral(self: Self) []const u8 {
        return switch (self) {
            inline else => |val| val.tokenLiteral(),
        };
    }

    pub fn node(self: Self) Node {
        return Node{ .statement = self };
    }

    pub fn string(self: Self, writer: anytype) !void {
        switch (self) {
            inline else => |statement| try statement.string(writer),
        }
    }
};

pub const LetStatement = struct {
    token: Token,
    name: Identifier,
    value: ?Expression = null,

    pub fn statement(self: @This()) Statement {
        return Statement{ .let = self };
    }

    pub fn tokenLiteral(self: @This()) []const u8 {
        return self.token.literal;
    }

    pub fn string(self: @This(), writer: anytype) !void {
        try std.fmt.format(writer, "{s} ", .{
            self.tokenLiteral(),
        });

        try self.name.string(writer);
        try std.fmt.format(writer, " = ", .{});

        if (self.value) |val| {
            try val.string(writer);
        }

        try std.fmt.format(writer, ";", .{});
    }
};

pub const ReturnStatement = struct {
    token: Token,
    value: ?Expression = null,

    pub fn statement(self: @This()) Statement {
        return Statement{ .@"return" = self };
    }

    pub fn tokenLiteral(self: @This()) []const u8 {
        return self.token.literal;
    }

    pub fn string(self: @This(), writer: anytype) !void {
        try std.fmt.format(writer, "{s} ", .{self.tokenLiteral()});

        if (self.value) |value| {
            try value.string(writer);
        }

        try std.fmt.format(writer, ";", .{});
    }
};

pub const ExpressionStatement = struct {
    token: Token,
    expression: ?Expression = null,

    pub fn statement(self: @This()) []const u8 {
        return Statement{ .expression = self };
    }

    pub fn tokenLiteral(self: @This()) []const u8 {
        return self.token.literal;
    }

    pub fn string(self: @This(), writer: anytype) !void {
        if (self.expression) |expression| {
            try expression.string(writer);
        }
    }
};

//  ── Expressions ─────────────────────────────────────────────────────

pub const ExpressionTag = enum {
    identifier,
};

pub const Expression = union(ExpressionTag) {
    const Self = @This();

    identifier: Identifier,

    pub fn tokenLiteral(self: Self) []const u8 {
        return switch (self) {
            inline else => |val| val.tokenLiteral(),
        };
    }

    pub fn node(self: Self) Node {
        return Node{ .expression = self };
    }

    pub fn string(self: Self, writer: anytype) !void {
        switch (self) {
            inline else => |expression| try expression.string(writer),
        }
    }
};

pub const Identifier = struct {
    token: Token,
    value: []const u8,

    pub fn statement(self: @This()) Statement {
        return Statement{ .let = self };
    }

    pub fn tokenLiteral(self: @This()) []const u8 {
        return self.token.literal;
    }

    pub fn string(self: @This(), writer: anytype) !void {
        try std.fmt.format(writer, "{s}", .{self.value});
    }
};

//  ── Tests ───────────────────────────────────────────────────────────

const testing = std.testing;

test "To String" {
    var program = Program.init(testing.allocator);
    defer program.deinit();

    try program.addStatement(Statement{ .let = LetStatement{
        .token = Token{ .type_ = .let, .literal = "let" },
        .name = Identifier{
            .token = Token{ .type_ = .ident, .literal = "myVar" },
            .value = "myVar",
        },
        .value = Expression{ .identifier = Identifier{
            .token = Token{ .type_ = .ident, .literal = "anotherVar" },
            .value = "anotherVar",
        } },
    } });

    var buffer = ArrayList(u8).init(testing.allocator);
    defer buffer.deinit();

    try program.string(buffer.writer());
    try testing.expectEqualStrings("let myVar = anotherVar;", buffer.items);
}
