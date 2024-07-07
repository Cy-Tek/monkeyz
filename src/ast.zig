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

    pub fn tokenLiteral(self: @This()) []const u8 {
        return if (self.statements.len > 0)
            self.statements[0].tokenLiteral()
        else
            "";
    }
};

//  ── Statements ──────────────────────────────────────────────────────

pub const StatementTag = enum {
    let,
    @"return",
};

pub const Statement = union(StatementTag) {
    const Self = @This();

    let: LetStatement,
    @"return": ReturnStatement,

    pub fn tokenLiteral(self: Self) []const u8 {
        return switch (self) {
            inline else => |val| val.tokenLiteral(),
        };
    }

    pub fn node(self: Self) Node {
        return Node{ .statement = self };
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
};
